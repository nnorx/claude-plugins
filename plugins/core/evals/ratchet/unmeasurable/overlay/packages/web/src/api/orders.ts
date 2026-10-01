import { legacyFetch } from "./legacy";

export const listOrders = (filters?: any) => legacyFetch(`/orders?${new URLSearchParams(filters)}`);
export const getOrder = (id: string) => legacyFetch(`/orders/${id}`);
export const getInvoice = (id: string, opts?: any) => legacyFetch(`/orders/${id}/invoice`);
export const getShipment = (id: string): Promise<any> => legacyFetch(`/orders/${id}/shipment`);
