"use client";

import { useState } from "react";
import { useParams, useRouter } from "next/navigation";
import Link from "next/link";
import {
  useUserDetail,
  useUpdateUser,
  useDeleteUser,
  useUserOrders,
  useAdjustLoyalty,
} from "@/hooks/use-users";
import { LOYALTY_TIERS } from "@/lib/constants";
import { toast } from "sonner";
import { format } from "date-fns";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogFooter,
  DialogDescription,
} from "@/components/ui/dialog";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Separator } from "@/components/ui/separator";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  ArrowLeft,
  Loader2,
  QrCode,
  Star,
  Coins,
  Pencil,
  Trash2,
  ShieldCheck,
  ShoppingBag,
} from "lucide-react";

function formatKGS(amount: number) {
  return new Intl.NumberFormat("ru-RU").format(amount) + " KGS";
}

function tierLabel(tier: string) {
  const entry = LOYALTY_TIERS.find((t) => t.name === tier);
  if (!entry) return tier;
  return `${tier.charAt(0).toUpperCase() + tier.slice(1)} (${entry.cashback}%)`;
}

const STATUS_LABELS: Record<string, string> = {
  pending: "Ожидает",
  payment_confirmed: "Оплачен",
  processing: "В обработке",
  ready_for_pickup: "Готов",
  shipped: "Отправлен",
  delivered: "Доставлен",
  cancelled: "Отменён",
};

export default function UserDetailPage() {
  const params = useParams<{ id: string }>();
  const router = useRouter();
  const id = params.id;

  const { data, isLoading } = useUserDetail(id);
  const updateUser = useUpdateUser();
  const deleteUser = useDeleteUser();
  const adjustLoyalty = useAdjustLoyalty();
  const { data: ordersData } = useUserOrders(id);

  // Edit dialog state
  const [editOpen, setEditOpen] = useState(false);
  const [editName, setEditName] = useState("");
  const [editEmail, setEditEmail] = useState("");

  // Points dialog state
  const [pointsOpen, setPointsOpen] = useState(false);
  const [pointsChange, setPointsChange] = useState<number>(0);
  const [description, setDescription] = useState("");

  const openEditDialog = () => {
    if (data?.user) {
      setEditName(data.user.full_name || "");
      setEditEmail(data.user.email || "");
    }
    setEditOpen(true);
  };

  const handleEdit = () => {
    updateUser.mutate(
      { id, full_name: editName, email: editEmail || undefined },
      {
        onSuccess: () => {
          toast.success("Профиль обновлён");
          setEditOpen(false);
        },
        onError: () => toast.error("Ошибка обновления"),
      },
    );
  };

  const handleToggleAdmin = () => {
    if (!data?.user) return;
    updateUser.mutate(
      { id, is_admin: !data.user.is_admin },
      {
        onSuccess: () =>
          toast.success(
            data.user.is_admin ? "Роль админа снята" : "Назначен админом",
          ),
        onError: () => toast.error("Ошибка изменения роли"),
      },
    );
  };

  const handleDelete = () => {
    deleteUser.mutate(id, {
      onSuccess: () => {
        toast.success("Пользователь удалён");
        router.push("/users");
      },
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      onError: (err: any) => {
        const msg =
          err?.response?.data?.detail || "Ошибка удаления пользователя";
        toast.error(msg);
      },
    });
  };

  const handleAdjust = () => {
    if (!pointsChange || !description.trim()) {
      toast.error("Заполните все поля");
      return;
    }
    adjustLoyalty.mutate(
      { user_id: id, points_change: pointsChange, description },
      {
        onSuccess: () => {
          toast.success("Баллы скорректированы");
          setPointsChange(0);
          setDescription("");
          setPointsOpen(false);
        },
        onError: () => toast.error("Ошибка корректировки баллов"),
      },
    );
  };

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-8 w-48" />
        <div className="grid gap-6 md:grid-cols-2">
          <Skeleton className="h-64" />
          <Skeleton className="h-64" />
        </div>
      </div>
    );
  }

  if (!data) {
    return (
      <div className="space-y-4">
        <h1 className="text-2xl font-semibold">Пользователь не найден</h1>
        <Button variant="outline" asChild>
          <Link href="/users">Назад</Link>
        </Button>
      </div>
    );
  }

  const { user, loyalty } = data;
  const orders = ordersData?.items ?? [];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Button variant="ghost" size="icon" asChild>
            <Link href="/users">
              <ArrowLeft />
            </Link>
          </Button>
          <h1 className="text-2xl font-semibold tracking-tight">
            {user.full_name || user.phone}
          </h1>
          {user.is_admin && <Badge variant="default">Админ</Badge>}
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={openEditDialog}>
            <Pencil className="size-3.5 mr-1" />
            Редактировать
          </Button>
          <AlertDialog>
            <AlertDialogTrigger asChild>
              <Button
                variant="destructive"
                size="sm"
                disabled={user.is_admin}
              >
                <Trash2 className="size-3.5 mr-1" />
                Удалить
              </Button>
            </AlertDialogTrigger>
            <AlertDialogContent>
              <AlertDialogHeader>
                <AlertDialogTitle>Удалить пользователя?</AlertDialogTitle>
                <AlertDialogDescription>
                  Это действие необратимо. Все данные пользователя{" "}
                  <strong>{user.full_name}</strong> будут удалены.
                </AlertDialogDescription>
              </AlertDialogHeader>
              <AlertDialogFooter>
                <AlertDialogCancel>Отмена</AlertDialogCancel>
                <AlertDialogAction onClick={handleDelete}>
                  Удалить
                </AlertDialogAction>
              </AlertDialogFooter>
            </AlertDialogContent>
          </AlertDialog>
        </div>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {/* User info */}
        <Card>
          <CardHeader>
            <CardTitle>Информация</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3 text-sm">
            <div className="grid grid-cols-2 gap-2">
              <span className="text-muted-foreground">Имя</span>
              <span>{user.full_name || "-"}</span>

              <span className="text-muted-foreground">Телефон</span>
              <span>{user.phone}</span>

              <span className="text-muted-foreground">Email</span>
              <span>{user.email || "-"}</span>

              <span className="text-muted-foreground">Дата рождения</span>
              <span>
                {user.birth_date
                  ? format(new Date(user.birth_date), "dd.MM.yyyy")
                  : "-"}
              </span>

              <span className="text-muted-foreground">Язык</span>
              <span>{user.language}</span>

              <span className="text-muted-foreground">Реферальный код</span>
              <span className="font-mono text-xs">{user.referral_code}</span>

              <span className="text-muted-foreground">Регистрация</span>
              <span>
                {format(new Date(user.created_at), "dd.MM.yyyy HH:mm")}
              </span>
            </div>

            <Separator />

            {/* Admin toggle */}
            <div className="flex items-center justify-between pt-1">
              <div className="flex items-center gap-2">
                <ShieldCheck className="size-4 text-muted-foreground" />
                <span className="text-sm font-medium">Права администратора</span>
              </div>
              <Switch
                checked={user.is_admin}
                onCheckedChange={handleToggleAdmin}
                disabled={updateUser.isPending}
              />
            </div>
          </CardContent>
        </Card>

        {/* Loyalty info */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle>Лояльность</CardTitle>
            <Dialog open={pointsOpen} onOpenChange={setPointsOpen}>
              <DialogTrigger asChild>
                <Button variant="outline" size="sm">
                  <Coins className="size-3.5 mr-1" />
                  Корректировать
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Корректировка баллов</DialogTitle>
                  <DialogDescription>
                    Введите положительное число для начисления, отрицательное для
                    списания.
                  </DialogDescription>
                </DialogHeader>
                <div className="grid gap-4">
                  <div className="grid gap-1.5">
                    <Label htmlFor="points_change">Баллы (+/-)</Label>
                    <Input
                      id="points_change"
                      type="number"
                      value={pointsChange}
                      onChange={(e) =>
                        setPointsChange(Number(e.target.value))
                      }
                      placeholder="100 или -50"
                    />
                  </div>
                  <div className="grid gap-1.5">
                    <Label htmlFor="adj_desc">Описание</Label>
                    <Textarea
                      id="adj_desc"
                      rows={2}
                      value={description}
                      onChange={(e) => setDescription(e.target.value)}
                      placeholder="Причина корректировки..."
                    />
                  </div>
                </div>
                <DialogFooter>
                  <Button
                    onClick={handleAdjust}
                    disabled={adjustLoyalty.isPending}
                  >
                    {adjustLoyalty.isPending && (
                      <Loader2 className="mr-2 size-4 animate-spin" />
                    )}
                    Применить
                  </Button>
                </DialogFooter>
              </DialogContent>
            </Dialog>
          </CardHeader>
          <CardContent className="space-y-3 text-sm">
            {loyalty ? (
              <>
                <div className="grid grid-cols-2 gap-2">
                  <span className="text-muted-foreground">
                    <Star className="mr-1 inline size-3.5" />
                    Уровень
                  </span>
                  <span className="font-medium">{tierLabel(loyalty.tier)}</span>

                  <span className="text-muted-foreground">
                    <Coins className="mr-1 inline size-3.5" />
                    Баллы
                  </span>
                  <span className="font-medium">{loyalty.points}</span>

                  <span className="text-muted-foreground">Всего потрачено</span>
                  <span>{formatKGS(loyalty.total_spent)}</span>
                </div>

                <Separator />

                <div className="grid grid-cols-2 gap-2">
                  <span className="text-muted-foreground">
                    <QrCode className="mr-1 inline size-3.5" />
                    QR-код
                  </span>
                  <span className="break-all font-mono text-xs">
                    {loyalty.qr_code}
                  </span>
                </div>
              </>
            ) : (
              <p className="text-muted-foreground">
                Нет данных о лояльности
              </p>
            )}
          </CardContent>
        </Card>
      </div>

      {/* User orders */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <ShoppingBag className="size-4" />
            Заказы ({ordersData?.total ?? 0})
          </CardTitle>
        </CardHeader>
        <CardContent>
          {orders.length === 0 ? (
            <p className="text-sm text-muted-foreground">Заказов пока нет</p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Номер</TableHead>
                  <TableHead>Статус</TableHead>
                  <TableHead>Сумма</TableHead>
                  <TableHead>Доставка</TableHead>
                  <TableHead>Дата</TableHead>
                  <TableHead />
                </TableRow>
              </TableHeader>
              <TableBody>
                {/* eslint-disable-next-line @typescript-eslint/no-explicit-any */}
                {orders.map((o: any) => (
                  <TableRow key={o.id}>
                    <TableCell className="font-mono text-xs">
                      {o.order_number}
                    </TableCell>
                    <TableCell>
                      <Badge variant="outline" className="text-xs">
                        {STATUS_LABELS[o.status] || o.status}
                      </Badge>
                    </TableCell>
                    <TableCell>{formatKGS(o.total)}</TableCell>
                    <TableCell className="text-xs">
                      {o.delivery_type === "pickup" ? "Самовывоз" : "Доставка"}
                    </TableCell>
                    <TableCell className="text-xs">
                      {format(new Date(o.created_at), "dd.MM.yy HH:mm")}
                    </TableCell>
                    <TableCell>
                      <Button variant="ghost" size="sm" asChild>
                        <Link href={`/orders/${o.id}`}>Открыть</Link>
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Edit dialog */}
      <Dialog open={editOpen} onOpenChange={setEditOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Редактировать профиль</DialogTitle>
          </DialogHeader>
          <div className="grid gap-4">
            <div className="grid gap-1.5">
              <Label htmlFor="edit_name">Имя</Label>
              <Input
                id="edit_name"
                value={editName}
                onChange={(e) => setEditName(e.target.value)}
              />
            </div>
            <div className="grid gap-1.5">
              <Label htmlFor="edit_email">Email</Label>
              <Input
                id="edit_email"
                type="email"
                value={editEmail}
                onChange={(e) => setEditEmail(e.target.value)}
              />
            </div>
          </div>
          <DialogFooter>
            <Button onClick={handleEdit} disabled={updateUser.isPending}>
              {updateUser.isPending && (
                <Loader2 className="mr-2 size-4 animate-spin" />
              )}
              Сохранить
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
