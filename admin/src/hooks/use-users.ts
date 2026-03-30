"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import api from "@/lib/api-client";
import type { User, AdminUserUpdate } from "@/types/user";
import type { LoyaltyAccount, AdminLoyaltyAdjust } from "@/types/loyalty";
import type { PaginatedResponse } from "@/types/common";

interface UsersParams {
  search?: string;
  page?: number;
  per_page?: number;
}

interface UserDetail {
  user: User;
  loyalty: LoyaltyAccount;
}

export function useUsers(params: UsersParams = {}) {
  return useQuery({
    queryKey: ["users", params],
    queryFn: async () => {
      const { data } = await api.get<PaginatedResponse<User>>(
        "/api/v1/admin/users",
        { params },
      );
      return data;
    },
  });
}

export function useUserDetail(id: string) {
  return useQuery({
    queryKey: ["users", id],
    queryFn: async () => {
      const { data } = await api.get<UserDetail>(
        `/api/v1/admin/users/${id}`,
      );
      return data;
    },
    enabled: !!id,
  });
}

export function useUpdateUser() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      id,
      ...update
    }: AdminUserUpdate & { id: string }) => {
      const { data } = await api.patch<User>(
        `/api/v1/admin/users/${id}`,
        update,
      );
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["users"] });
    },
  });
}

export function useDeleteUser() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      await api.delete(`/api/v1/admin/users/${id}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["users"] });
    },
  });
}

export function useUserOrders(userId: string, page = 1) {
  return useQuery({
    queryKey: ["users", userId, "orders", page],
    queryFn: async () => {
      const { data } = await api.get(
        `/api/v1/admin/users/${userId}/orders`,
        { params: { page, per_page: 10 } },
      );
      return data;
    },
    enabled: !!userId,
  });
}

export function useAdjustLoyalty() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      user_id,
      ...body
    }: AdminLoyaltyAdjust) => {
      const { data } = await api.post(
        `/api/v1/admin/users/${user_id}/loyalty/adjust`,
        body,
      );
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["users"] });
    },
  });
}
