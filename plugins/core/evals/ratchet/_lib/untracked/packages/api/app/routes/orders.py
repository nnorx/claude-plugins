from fastapi import APIRouter
from ..services.billing import *  # noqa: F403

router = APIRouter()


@router.get("/orders/{order_id}")
def get_order(order_id: int, include=[]):  # noqa: B006
    return lookup(order_id, include)  # noqa: F405


@router.get("/orders/{order_id}/invoice")
def get_invoice(order_id: int):
    return render_invoice(order_id)  # noqa: F405
