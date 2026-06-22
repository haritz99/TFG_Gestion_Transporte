import os
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText


class EmailService:

    def __init__(self):
        self.smtp_server = "smtp.gmail.com"
        self.smtp_port = 587

        self.sender_email = os.getenv("EMAIL_USER")
        self.sender_password = os.getenv("EMAIL_PASSWORD")

    def send_welcome_email(self, email: str, temp_password: str, reset_link: str):
        msg = MIMEMultipart()
        msg["From"] = f"Sistema de Gestión de Flotas <{self.sender_email}>"
        msg["To"] = email
        msg["Subject"] = "Bienvenido a la plataforma de transporte."

        body = f"""
        Estimado/a,

        Le informamos de que se le ha dado de alta en el sistema. Sus credenciales de acceso para su primer inicio de sesión:

        Usuario: {email}
        Contraseña temporal: {temp_password}

        Puede actualizar su contraseña inicial antes de comenzar su actividad directamente a través del siguiente enlace:

        {reset_link}

        Un saludo,
        """
        msg.attach(MIMEText(body, "plain", "utf-8"))

        try:
            server = smtplib.SMTP(self.smtp_server, self.smtp_port)
            server.starttls()
            server.login(self.sender_email, self.sender_password)
            server.send_message(msg)
            print(f"Notificación de alta enviada correctamente a: {email}")

        except smtplib.SMTPAuthenticationError:
            print("Error de autenticación SMTP: Revise EMAIL_USER y EMAIL_PASSWORD.")
        except Exception as e:
            print(f"Error al enviar la notificación de alta a {email}: {str(e)}")
        finally:
            try:
                server.quit()
            except NameError:
                pass


def get_email_service() -> EmailService:
    return EmailService()