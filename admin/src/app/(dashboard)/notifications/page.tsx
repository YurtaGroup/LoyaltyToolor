"use client";

import { useState } from "react";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import api from "@/lib/api-client";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Loader2 } from "lucide-react";

interface NotificationForm {
  title: string;
  body: string;
  type: string;
  user_id: string;
}

interface SentNotification {
  title: string;
  body: string;
  type: string;
  user_id?: string;
  sent_at: string;
}

const NOTIFICATION_TYPES = [
  { value: "order_update", label: "Обновление заказа" },
  { value: "promo", label: "Промо" },
  { value: "loyalty", label: "Лояльность" },
  { value: "system", label: "Системное" },
] as const;

export default function NotificationsPage() {
  const [sending, setSending] = useState(false);
  const [sent, setSent] = useState<SentNotification[]>([]);

  const { register, handleSubmit, setValue, watch, reset, formState: { errors } } =
    useForm<NotificationForm>({
      defaultValues: {
        title: "",
        body: "",
        type: "system",
        user_id: "",
      },
    });

  const onSubmit = async (values: NotificationForm) => {
    setSending(true);
    try {
      const payload: { title: string; body: string; type: string; user_id?: string } = {
        title: values.title,
        body: values.body,
        type: values.type,
      };
      if (values.user_id.trim()) {
        payload.user_id = values.user_id.trim();
      }
      await api.post("/api/v1/admin/notifications/send", payload);
      toast.success("Уведомление отправлено");
      setSent((prev) => [
        {
          title: values.title,
          body: values.body,
          type: values.type,
          user_id: values.user_id.trim() || undefined,
          sent_at: new Date().toISOString(),
        },
        ...prev,
      ]);
      reset();
    } catch {
      toast.error("Ошибка отправки уведомления");
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold tracking-tight">Уведомления</h1>

      <Card>
        <CardHeader>
          <CardTitle>Отправить уведомление</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className="grid gap-4 md:grid-cols-2">
            <div className="grid gap-1.5 md:col-span-2">
              <Label htmlFor="title">Заголовок</Label>
              <Input
                id="title"
                {...register("title", { required: "Обязательное поле" })}
                placeholder="Заголовок уведомления"
                aria-invalid={!!errors.title}
              />
              {errors.title && (
                <p className="text-xs text-destructive">{errors.title.message}</p>
              )}
            </div>

            <div className="grid gap-1.5 md:col-span-2">
              <Label htmlFor="body">Текст</Label>
              <Textarea
                id="body"
                rows={3}
                {...register("body", { required: "Обязательное поле" })}
                placeholder="Текст уведомления"
                aria-invalid={!!errors.body}
              />
              {errors.body && (
                <p className="text-xs text-destructive">{errors.body.message}</p>
              )}
            </div>

            <div className="grid gap-1.5">
              <Label>Тип</Label>
              <Select
                value={watch("type")}
                onValueChange={(val) => setValue("type", val)}
              >
                <SelectTrigger className="w-full">
                  <SelectValue placeholder="Выберите тип" />
                </SelectTrigger>
                <SelectContent>
                  {NOTIFICATION_TYPES.map((t) => (
                    <SelectItem key={t.value} value={t.value}>
                      {t.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="grid gap-1.5">
              <Label htmlFor="user_id">ID пользователя (необязательно)</Label>
              <Input
                id="user_id"
                {...register("user_id")}
                placeholder="Оставьте пустым для рассылки всем"
              />
            </div>

            <div className="md:col-span-2">
              <Button type="submit" disabled={sending} className="w-full sm:w-auto">
                {sending && <Loader2 className="mr-2 size-4 animate-spin" />}
                Отправить
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      {sent.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Отправленные уведомления</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {sent.map((n, i) => (
                <div
                  key={i}
                  className="flex flex-col gap-1 rounded-lg border p-3"
                >
                  <div className="flex items-center justify-between">
                    <span className="font-medium">{n.title}</span>
                    <span className="text-xs text-muted-foreground">
                      {new Date(n.sent_at).toLocaleString("ru-RU")}
                    </span>
                  </div>
                  <p className="text-sm text-muted-foreground">{n.body}</p>
                  <div className="flex gap-2 text-xs text-muted-foreground">
                    <span>
                      Тип: {NOTIFICATION_TYPES.find((t) => t.value === n.type)?.label ?? n.type}
                    </span>
                    {n.user_id && <span>| Пользователь: {n.user_id}</span>}
                    {!n.user_id && <span>| Всем пользователям</span>}
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
