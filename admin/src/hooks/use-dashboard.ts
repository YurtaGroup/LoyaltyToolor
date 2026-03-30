"use client";

import { useQuery } from "@tanstack/react-query";
import api from "@/lib/api-client";
import type { DashboardData, MetricsData } from "@/types/dashboard";

export function useDashboard() {
  return useQuery({
    queryKey: ["dashboard"],
    queryFn: async () => {
      const { data } = await api.get<DashboardData>(
        "/api/v1/admin/dashboard",
      );
      return data;
    },
  });
}

export function useMetrics(days = 30) {
  return useQuery({
    queryKey: ["metrics", days],
    queryFn: async () => {
      const { data } = await api.get<MetricsData>(
        "/api/v1/admin/metrics",
        { params: { days } },
      );
      return data;
    },
  });
}
