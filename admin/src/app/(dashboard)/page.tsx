"use client";

import { useState } from "react";
import { useDashboard, useMetrics } from "@/hooks/use-dashboard";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Users,
  ShoppingCart,
  Banknote,
  Clock,
  TrendingUp,
  Repeat,
  Target,
  BarChart3,
} from "lucide-react";
import { ORDER_STATUSES } from "@/lib/constants";
import { format } from "date-fns";
import Link from "next/link";

function formatKGS(amount: number) {
  return new Intl.NumberFormat("ru-RU").format(amount) + " KGS";
}

function statusLabel(value: string) {
  return ORDER_STATUSES.find((s) => s.value === value)?.label ?? value;
}

export default function DashboardPage() {
  const { data, isLoading } = useDashboard();
  const [metricsDays, setMetricsDays] = useState(30);
  const { data: metrics, isLoading: metricsLoading } = useMetrics(metricsDays);

  if (isLoading) {
    return (
      <div className="space-y-6">
        <h1 className="text-2xl font-semibold tracking-tight">
          Панель управления
        </h1>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <Card key={i}>
              <CardHeader>
                <Skeleton className="h-4 w-24" />
              </CardHeader>
              <CardContent>
                <Skeleton className="h-8 w-20" />
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  const stats = [
    {
      title: "Пользователи",
      value: data?.total_users ?? 0,
      icon: Users,
    },
    {
      title: "Заказы",
      value: data?.total_orders ?? 0,
      icon: ShoppingCart,
    },
    {
      title: "Выручка",
      value: formatKGS(data?.total_revenue ?? 0),
      icon: Banknote,
    },
    {
      title: "Ожидающие",
      value: data?.pending_orders ?? 0,
      icon: Clock,
    },
  ];

  const metricCards = metrics
    ? [
        {
          title: "DAU (среднее)",
          value: metrics.avg_dau.toFixed(1),
          icon: TrendingUp,
          desc: "активных пользователей в день",
        },
        {
          title: "Конверсия",
          value: `${metrics.conversion_rate_pct}%`,
          icon: Target,
          desc: `${metrics.total_buyers_period} из ${metrics.total_users_period} купили`,
        },
        {
          title: "Средний чек",
          value: formatKGS(metrics.aov),
          icon: BarChart3,
          desc: `${metrics.paid_orders} оплаченных заказов`,
        },
        {
          title: "Повторные покупки",
          value: `${metrics.repeat_purchase_rate_pct}%`,
          icon: Repeat,
          desc: `${metrics.repeat_buyers} покупателей вернулись`,
        },
      ]
    : [];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold tracking-tight">
        Панель управления
      </h1>

      {/* Core stats */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => (
          <Card key={stat.title}>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                {stat.title}
              </CardTitle>
              <stat.icon className="size-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <p className="text-2xl font-bold">{stat.value}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Analytics metrics */}
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold">Аналитика</h2>
        <Select
          value={String(metricsDays)}
          onValueChange={(v) => setMetricsDays(Number(v))}
        >
          <SelectTrigger className="w-40">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="7">7 дней</SelectItem>
            <SelectItem value="30">30 дней</SelectItem>
            <SelectItem value="90">90 дней</SelectItem>
            <SelectItem value="365">За год</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {metricsLoading
          ? Array.from({ length: 4 }).map((_, i) => (
              <Card key={i}>
                <CardHeader>
                  <Skeleton className="h-4 w-24" />
                </CardHeader>
                <CardContent>
                  <Skeleton className="h-8 w-20" />
                </CardContent>
              </Card>
            ))
          : metricCards.map((m) => (
              <Card key={m.title}>
                <CardHeader className="flex flex-row items-center justify-between pb-2">
                  <CardTitle className="text-sm font-medium text-muted-foreground">
                    {m.title}
                  </CardTitle>
                  <m.icon className="size-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <p className="text-2xl font-bold">{m.value}</p>
                  <p className="text-xs text-muted-foreground mt-1">
                    {m.desc}
                  </p>
                </CardContent>
              </Card>
            ))}
      </div>

      {/* Metrics revenue card */}
      {metrics && (
        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Выручка за {metricsDays} дней
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-3xl font-bold">{formatKGS(metrics.revenue)}</p>
          </CardContent>
        </Card>
      )}

      {/* Recent orders */}
      <Card>
        <CardHeader>
          <CardTitle>Последние заказы</CardTitle>
        </CardHeader>
        <CardContent>
          {data?.recent_orders && data.recent_orders.length > 0 ? (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Номер</TableHead>
                  <TableHead>Статус</TableHead>
                  <TableHead>Сумма</TableHead>
                  <TableHead>Дата</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {data.recent_orders.map((order) => (
                  <TableRow key={order.id}>
                    <TableCell>
                      <Link
                        href={`/orders/${order.id}`}
                        className="font-medium hover:underline"
                      >
                        {order.order_number}
                      </Link>
                    </TableCell>
                    <TableCell>
                      <Badge variant="secondary">
                        {statusLabel(order.status)}
                      </Badge>
                    </TableCell>
                    <TableCell>{formatKGS(order.total)}</TableCell>
                    <TableCell>
                      {format(new Date(order.created_at), "dd.MM.yyyy HH:mm")}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          ) : (
            <p className="text-sm text-muted-foreground">Заказов пока нет</p>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
