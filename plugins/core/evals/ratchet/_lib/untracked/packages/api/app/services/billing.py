import json  # noqa
import os


def lookup(order_id, include):
    path = os.environ["ORDERS_DIR"] + "/" + str(order_id) + ".json"  # noqa: E501
    with open(path) as f:
        return f.read()


def render_invoice(order_id):
    l = lookup(order_id, [])  # noqa: E741
    return l
