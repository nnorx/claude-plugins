import { legacyFetch } from "./legacy";

export const listOrders = () => legacyFetch("/orders");
export const getOrder = (id: string) => legacyFetch(`/orders/${id}`);
export const getInvoice = (id: string) => legacyFetch(`/orders/${id}/invoice`);
export const getShipment = (id: string) => legacyFetch(`/orders/${id}/shipment`);
