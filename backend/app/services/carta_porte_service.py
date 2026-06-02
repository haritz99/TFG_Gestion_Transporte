from __future__ import annotations

import datetime
from firebase_admin import storage
import re
from pathlib import Path
from typing import Any
from fastapi import Depends, HTTPException
from app.crud.cargas_crud import CargasCRUD
from datetime import timedelta


try:
	from jinja2 import Environment, FileSystemLoader, select_autoescape
except ImportError:
	Environment = None
	FileSystemLoader = None
	select_autoescape = None

try:
	from weasyprint import HTML
except Exception:
	HTML = None


class CartaPorteService:
	_TEMPLATE_DIR = Path(__file__).resolve().parents[2] / "templates"

	def __init__(self, crud: CargasCRUD = Depends(CargasCRUD)):
		self._crud = crud

	@staticmethod
	def _camel_to_snake(value: str) -> str:
		value = re.sub(r"(.)([A-Z][a-z]+)", r"\1_\2", value)
		return re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", value).lower()

	@classmethod
	def _normalize_for_template(cls, value: Any) -> Any:
		if isinstance(value, dict):
			return {
				cls._camel_to_snake(str(key)): cls._normalize_for_template(value)
				for key, value in value.items()
			}
		if isinstance(value, list):
			return [cls._normalize_for_template(item) for item in value]
		if isinstance(value, tuple):
			return tuple(cls._normalize_for_template(item) for item in value)
		if isinstance(value, datetime.datetime):
			dt = value if value.tzinfo else value.replace(tzinfo=datetime.timezone.utc)
			dt = dt.astimezone(datetime.timezone.utc)
			return dt.strftime("%d/%m/%Y %H:%M")
		if isinstance(value, datetime.date):
			return value.strftime("%d/%m/%Y")
		return value

	def get_carta_porte_template_data(self, carga_id: str, company_id: str) -> dict[str, Any]:
		doc = self._crud.get_carga_doc(carga_id)
		if not doc.exists:
			raise HTTPException(status_code=404, detail="Carga no encontrada")

		carga_data = doc.to_dict() or {}
		if carga_data.get("companyId") != company_id:
			raise HTTPException(status_code=403, detail="No autorizado para generar la carta de porte de esta carga")

		carga_data["id"] = doc.id
		carga_data = self._normalize_for_template(carga_data)

		if isinstance(carga_data, dict):
			snapshot = carga_data.get("carta_porte_snapshot")
			if isinstance(snapshot, dict):
				for key in (
					"cliente_nombre",
					"cliente_nif",
					"cliente_direccion",
					"cliente_telefono",
					"subcontratado_nombre",
					"subcontratado_nif",
					"subcontratado_direccion",
					"subcontratado_telefono",
					"subcontratado_num_autorizacion",
					"precio_neto",
					"congelado_at",
				):
					if carga_data.get(key) is None and snapshot.get(key) is not None:
						carga_data[key] = snapshot.get(key)

			precio = carga_data.get("precio")
			comision = carga_data.get("comision_cesion")
			if carga_data.get("precio_neto") is None and isinstance(precio, (int, float)) and isinstance(comision, (int, float)):
				carga_data["precio_neto"] = round(precio * (1 - comision / 100), 2)

		return carga_data

	def generar_carta_porte_pdf(self, carga_id: str, company_id: str) -> str:
		if Environment is None or FileSystemLoader is None or select_autoescape is None:
			raise HTTPException(status_code=500, detail="Jinja2 no está instalado")
		if HTML is None:
			raise HTTPException(status_code=500, detail="WeasyPrint no está instalado")

		carga = self.get_carta_porte_template_data(carga_id, company_id)
		template_dir = self._TEMPLATE_DIR
		template_path = template_dir / "carta_porte_template.html"
		if not template_path.exists():
			raise HTTPException(status_code=500, detail="No se encontró la plantilla de carta de porte")

		env = Environment(
			loader=FileSystemLoader(str(template_dir)),
			autoescape=select_autoescape(["html", "xml"]),
		)

		template = env.get_template("carta_porte_template.html")
		html = template.render(carga=carga)
		html_renderer = HTML
		assert html_renderer is not None

		pdf_bytes = html_renderer(string=html, base_url=str(template_dir)).write_pdf()
		blob_path = self.subir_pdf(pdf_bytes, carga_id, company_id)

		if not blob_path:
			raise HTTPException(status_code=500, detail="El PDF se generó pero falló la subida al almacenamiento")

		try:
			self._crud.update_carga_doc(carga_id, {"carta_porte_url": blob_path})
		except Exception as e:
			print(f"Error al actualizar la carga con la URL de la carta de porte: {e}")

		url_firmada = self.generar_url_firmada(blob_path)
		return url_firmada

	@staticmethod
	def subir_pdf(pdf_bytes, id_carga, company_id) -> str:
		bucket = storage.bucket()
		blob = bucket.blob(f"cartas_porte/{company_id}/carta_{id_carga}.pdf")
		blob.upload_from_string(pdf_bytes, content_type="application/pdf")
		return blob.name

	@staticmethod
	def generar_url_firmada(blob_path: str) -> str:
		bucket = storage.bucket()
		blob = bucket.blob(blob_path)
		url = blob.generate_signed_url(expiration=timedelta(hours=1))
		return url