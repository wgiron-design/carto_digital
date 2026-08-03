from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
import os

templates_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "templates")
templates = Jinja2Templates(directory=templates_dir)

router = APIRouter(tags=["Admin Web Panel"])

@router.get("/admin", response_class=HTMLResponse)
async def admin_dashboard(request: Request):
    return templates.TemplateResponse(request=request, name="admin.html")

@router.get("/reset-password-page", response_class=HTMLResponse)
async def reset_password_page(request: Request):
    return templates.TemplateResponse(request=request, name="reset_password.html")

