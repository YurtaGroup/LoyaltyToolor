import type { Order } from "./order";

export interface DashboardData {
  total_users: number;
  total_orders: number;
  total_revenue: number;
  pending_orders: number;
  recent_orders: Order[];
}

export interface MetricsData {
  period_days: number;
  avg_dau: number;
  conversion_rate_pct: number;
  aov: number;
  repeat_purchase_rate_pct: number;
  total_users_period: number;
  total_buyers_period: number;
  repeat_buyers: number;
  paid_orders: number;
  revenue: number;
}
