<script>
  import { router } from "@inertiajs/svelte";
  import { Button } from "$lib/components/ui/button";
  import { Input } from "$lib/components/ui/input";
  import { Label } from "$lib/components/ui/label";
  import { Textarea } from "$lib/components/ui/textarea";
  import {
    Card,
    CardContent,
    CardHeader,
    CardTitle,
  } from "$lib/components/ui/card";
  import { Badge } from "$lib/components/ui/badge";
  import {
    ArrowLeft,
    DollarSign,
    Calendar,
    AlertTriangle,
  } from "lucide-svelte";
  import { formatCurrency } from "$lib/billing-utils";

  export let project;
  export let billing_cycle;

  let form = {
    new_amount: billing_cycle.total_amount,
    new_due_date: billing_cycle.due_date,
    reason: "",
  };

  let errors = [];
  let processing = false;

  function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  }

  function handleSubmit() {
    processing = true;
    errors = [];

    router.post(
      `/projects/${project.slug}/billing_cycles/${billing_cycle.id}/adjust`,
      {
        adjustment: form,
      },
      {
        onError: (error) => {
          errors = Object.values(error).flat();
          processing = false;
        },
        onFinish: () => {
          processing = false;
        },
      },
    );
  }

  function goBack() {
    router.visit(
      `/projects/${project.slug}/billing_cycles/${billing_cycle.id}`,
    );
  }
</script>

<svelte:head>
  <title>Adjust Billing Cycle - {project.name} - SplitMySub</title>
</svelte:head>

<div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
  <!-- Header -->
  <div class="flex items-center gap-4 mb-6">
    <Button
      variant="ghost"
      size="sm"
      onclick={goBack}
      onkeydown={(e) => (e.key === "Enter" || e.key === " ") && goBack}
    >
      <ArrowLeft class="w-4 h-4 mr-2" />
      Back to Billing Cycle
    </Button>
    <div>
      <h1 class="text-3xl font-bold text-gray-900">Adjust Billing Cycle</h1>
      <p class="text-gray-600">{project.name}</p>
    </div>
  </div>

  <!-- Current Values -->
  <Card class="mb-6">
    <CardHeader>
      <CardTitle class="flex items-center gap-2">
        <AlertTriangle class="w-5 h-5 text-amber-500" />
        Current Billing Cycle Details
      </CardTitle>
    </CardHeader>
    <CardContent>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div class="space-y-2">
          <Label class="text-sm font-medium text-gray-600">Current Amount</Label
          >
          <div class="text-2xl font-bold text-gray-900">
            {formatCurrency(billing_cycle.total_amount, project.currency)}
          </div>
        </div>
        <div class="space-y-2">
          <Label class="text-sm font-medium text-gray-600"
            >Current Due Date</Label
          >
          <div class="text-lg font-semibold text-gray-900">
            {formatDate(billing_cycle.due_date)}
          </div>
        </div>
        <div class="space-y-2">
          <Label class="text-sm font-medium text-gray-600">Payment Status</Label
          >
          <Badge
            variant={billing_cycle.payment_status === "paid"
              ? "default"
              : billing_cycle.payment_status === "partial"
                ? "secondary"
                : "destructive"}
          >
            {billing_cycle.payment_status}
          </Badge>
        </div>
        <div class="space-y-2">
          <Label class="text-sm font-medium text-gray-600"
            >Payments Received</Label
          >
          <div class="text-lg font-semibold text-green-600">
            {formatCurrency(billing_cycle.total_paid, project.currency)}
          </div>
        </div>
      </div>
    </CardContent>
  </Card>

  <!-- Adjustment Form -->
  <Card>
    <CardHeader>
      <CardTitle>Make Adjustments</CardTitle>
      <p class="text-sm text-gray-600">
        Adjust the billing cycle amount or due date. Please provide a reason for
        the adjustment.
      </p>
    </CardHeader>
    <CardContent>
      <form
        onsubmit={(e) => {
          e.preventDefault();
          handleSubmit(e);
        }}
        class="space-y-6"
      >
        <!-- Error Messages -->
        {#if errors.length > 0}
          <div class="bg-red-50 border border-red-200 rounded-md p-4">
            <h4 class="text-red-800 font-medium mb-2">
              Please fix the following errors:
            </h4>
            <ul class="text-red-700 text-sm space-y-1">
              {#each errors as error}
                <li>• {error}</li>
              {/each}
            </ul>
          </div>
        {/if}

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- New Amount -->
          <div class="space-y-2">
            <Label for="new_amount">New Amount</Label>
            <div class="relative">
              <DollarSign
                class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4"
              />
              <Input
                id="new_amount"
                type="number"
                step="0.01"
                min="0.01"
                bind:value={form.new_amount}
                placeholder="0.00"
                class="pl-10"
              />
            </div>
            <p class="text-sm text-gray-600">
              Leave unchanged to keep current amount
            </p>
          </div>

          <!-- New Due Date -->
          <div class="space-y-2">
            <Label for="new_due_date">New Due Date</Label>
            <div class="relative">
              <Calendar
                class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4"
              />
              <Input
                id="new_due_date"
                type="date"
                bind:value={form.new_due_date}
                class="pl-10"
              />
            </div>
            <p class="text-sm text-gray-600">
              Leave unchanged to keep current due date
            </p>
          </div>
        </div>

        <!-- Reason -->
        <div class="space-y-2">
          <Label for="reason">Reason for Adjustment *</Label>
          <Textarea
            id="reason"
            bind:value={form.reason}
            placeholder="Please explain why this adjustment is necessary..."
            rows="3"
            required
          />
          <p class="text-sm text-gray-600">
            This reason will be recorded for audit purposes
          </p>
        </div>

        <!-- Warning -->
        <div class="bg-amber-50 border border-amber-200 rounded-md p-4">
          <div class="flex items-start gap-3">
            <AlertTriangle class="w-5 h-5 text-amber-500 mt-0.5" />
            <div>
              <h4 class="text-amber-800 font-medium">Important Notice</h4>
              <p class="text-amber-700 text-sm mt-1">
                Adjusting the billing cycle may affect member expectations and
                payment calculations.
                {#if billing_cycle.payments_count > 0}
                  This cycle already has {billing_cycle.payments_count} payment(s).
                {/if}
                Make sure to communicate any changes to project members.
              </p>
            </div>
          </div>
        </div>

        <!-- Submit Button -->
        <div class="flex justify-end gap-3">
          <Button
            variant="outline"
            type="button"
            onclick={goBack}
            onkeydown={(e) => (e.key === "Enter" || e.key === " ") && goBack}
          >
            Cancel
          </Button>
          <Button type="submit" disabled={processing || !form.reason.trim()}>
            {processing ? "Adjusting..." : "Apply Adjustment"}
          </Button>
        </div>
      </form>
    </CardContent>
  </Card>
</div>
