<script>
  import { router } from "@inertiajs/svelte";
  import Layout from "../../layouts/layout.svelte";
  import Button from "$lib/components/ui/button/button.svelte";
  import Input from "$lib/components/ui/input/input.svelte";
  import Label from "$lib/components/ui/label/label.svelte";
  import Card from "$lib/components/ui/card/card.svelte";
  import CardContent from "$lib/components/ui/card/card-content.svelte";
  import CardHeader from "$lib/components/ui/card/card-header.svelte";
  import CardTitle from "$lib/components/ui/card/card-title.svelte";
  import { ArrowLeft, Calendar, DollarSign, Save } from "lucide-svelte";

  export let project;
  export let billing_cycle;
  export let errors = [];

  let form = {
    due_date: billing_cycle.due_date || "",
    total_amount: billing_cycle.total_amount || "",
  };

  let isSubmitting = false;

  function handleSubmit() {
    if (isSubmitting) return;

    isSubmitting = true;
    router.patch(
      `/projects/${project.slug}/billing_cycles/${billing_cycle.id}`,
      {
        billing_cycle: form,
      },
      {
        onFinish: () => {
          isSubmitting = false;
        },
      },
    );
  }

  function formatCurrency(amount) {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
    }).format(amount);
  }

  function formatDate(dateString) {
    if (!dateString) return "";
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  }

  // Calculate per-member amount
  $: perMemberAmount = form.total_amount
    ? parseFloat(form.total_amount) / project.total_members
    : 0;

  // Validate form
  $: isFormValid =
    form.due_date && form.total_amount && parseFloat(form.total_amount) > 0;

  // Check if form has changes
  $: hasChanges =
    form.due_date !== billing_cycle.due_date ||
    parseFloat(form.total_amount) !== parseFloat(billing_cycle.total_amount);
</script>

<svelte:head>
  <title
    >Edit Billing Cycle - {formatDate(billing_cycle.due_date)} - {project.name} -
    SplitSub</title
  >
</svelte:head>

<Layout>
  <div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
    <!-- Header -->
    <div class="flex items-center justify-between mb-8">
      <div class="flex items-center gap-4">
        <a
          href="/projects/{project.slug}/billing_cycles/{billing_cycle.id}"
          class="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-muted-foreground hover:text-foreground hover:bg-accent hover:bg-opacity-50 rounded-md transition-colors cursor-pointer"
        >
          <ArrowLeft class="h-4 w-4" />
          Back to Billing Cycle
        </a>
      </div>
    </div>

    <!-- Project Header -->
    <div class="mb-8">
      <h1 class="text-3xl font-bold tracking-tight mb-2">Edit Billing Cycle</h1>
      <p class="text-muted-foreground text-lg">
        <strong>{project.name}</strong> - {formatDate(billing_cycle.due_date)}
      </p>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      <!-- Form -->
      <div class="lg:col-span-2">
        <Card>
          <CardHeader>
            <CardTitle class="flex items-center gap-2">
              <Calendar class="w-5 h-5" />
              Billing Cycle Details
            </CardTitle>
          </CardHeader>
          <CardContent>
            <form onsubmit={(e) => { e.preventDefault(); handleSubmit(e); }} class="space-y-6">
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

              <!-- Due Date -->
              <div class="space-y-2">
                <Label for="due_date">Due Date *</Label>
                <Input
                  id="due_date"
                  type="date"
                  bind:value={form.due_date}
                  required
                  class={errors.some((e) => e.includes("due_date"))
                    ? "border-destructive"
                    : ""}
                />
                <p class="text-sm text-gray-600">
                  When should members submit their payments by?
                </p>
              </div>

              <!-- Total Amount -->
              <div class="space-y-2">
                <Label for="total_amount">Total Amount *</Label>
                <div class="relative">
                  <DollarSign
                    class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4"
                  />
                  <Input
                    id="total_amount"
                    type="number"
                    step="0.01"
                    min="0.01"
                    bind:value={form.total_amount}
                    placeholder="0.00"
                    class="pl-10 {errors.some((e) => e.includes('total_amount'))
                      ? 'border-destructive'
                      : ''}"
                    required
                  />
                </div>
                <p class="text-sm text-gray-600">
                  Total amount to be collected for this billing cycle
                </p>
              </div>

              <!-- Warning about existing payments -->
              {#if billing_cycle.payments_count > 0}
                <div
                  class="bg-yellow-50 border border-yellow-200 rounded-md p-4"
                >
                  <h4 class="text-yellow-800 font-medium mb-2">⚠️ Warning</h4>
                  <p class="text-yellow-700 text-sm">
                    This billing cycle already has {billing_cycle.payments_count}
                    payment{billing_cycle.payments_count === 1 ? "" : "s"}.
                    Changing the total amount may affect payment calculations
                    and member expectations.
                  </p>
                </div>
              {/if}

              <!-- Submit Button -->
              <div class="flex gap-4 pt-4">
                <Button
                  type="submit"
                  disabled={!isFormValid || !hasChanges || isSubmitting}
                  class="flex-1 sm:flex-none"
                >
                  <Save class="w-4 h-4 mr-2" />
                  {isSubmitting ? "Saving..." : "Save Changes"}
                </Button>
                <Button
                  href="/projects/{project.slug}/billing_cycles/{billing_cycle.id}"
                  variant="outline"
                  disabled={isSubmitting}
                >
                  Cancel
                </Button>
              </div>

              {#if !hasChanges && isFormValid}
                <p class="text-sm text-gray-600">No changes to save.</p>
              {/if}
            </form>
          </CardContent>
        </Card>
      </div>

      <!-- Preview/Summary -->
      <div class="lg:col-span-1">
        <Card>
          <CardHeader>
            <CardTitle class="flex items-center gap-2">
              <DollarSign class="w-5 h-5" />
              Current Status
            </CardTitle>
          </CardHeader>
          <CardContent class="space-y-4">
            <!-- Current Billing Cycle Info -->
            <div class="bg-gray-50 p-4 rounded-lg">
              <h4 class="font-medium text-gray-900 mb-2">Current Values</h4>
              <div class="space-y-2 text-sm">
                <div class="flex justify-between">
                  <span class="text-gray-600">Due Date:</span>
                  <span class="font-medium"
                    >{formatDate(billing_cycle.due_date)}</span
                  >
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600">Total Amount:</span>
                  <span class="font-medium"
                    >{formatCurrency(billing_cycle.total_amount)}</span
                  >
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600">Per Member:</span>
                  <span class="font-medium"
                    >{formatCurrency(
                      billing_cycle.expected_payment_per_member,
                    )}</span
                  >
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600">Payments:</span>
                  <span class="font-medium">{billing_cycle.payments_count}</span
                  >
                </div>
              </div>
            </div>

            <!-- Updated Preview -->
            <div class="bg-blue-50 p-4 rounded-lg">
              <h4 class="font-medium text-gray-900 mb-2">Updated Values</h4>
              <div class="space-y-2 text-sm">
                <div class="flex justify-between">
                  <span class="text-gray-600">Due Date:</span>
                  <span
                    class="font-medium {form.due_date !== billing_cycle.due_date
                      ? 'text-blue-600'
                      : ''}"
                  >
                    {form.due_date ? formatDate(form.due_date) : "Not set"}
                  </span>
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600">Total Amount:</span>
                  <span
                    class="font-medium text-lg {parseFloat(
                      form.total_amount,
                    ) !== parseFloat(billing_cycle.total_amount)
                      ? 'text-blue-600'
                      : ''}"
                  >
                    {form.total_amount
                      ? formatCurrency(parseFloat(form.total_amount))
                      : "$0.00"}
                  </span>
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600">Per Member:</span>
                  <span
                    class="font-medium {parseFloat(form.total_amount) !==
                    parseFloat(billing_cycle.total_amount)
                      ? 'text-blue-600'
                      : ''}"
                  >
                    {perMemberAmount > 0
                      ? formatCurrency(perMemberAmount)
                      : "$0.00"}
                  </span>
                </div>
              </div>
            </div>

            <!-- Payment Progress -->
            <div class="bg-green-50 p-4 rounded-lg">
              <h4 class="font-medium text-gray-900 mb-2">Payment Progress</h4>
              <div class="space-y-2 text-sm">
                <div class="flex justify-between">
                  <span class="text-gray-600">Amount Paid:</span>
                  <span class="font-medium text-green-600"
                    >{formatCurrency(billing_cycle.total_paid)}</span
                  >
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600">Remaining:</span>
                  <span class="font-medium text-red-600"
                    >{formatCurrency(billing_cycle.amount_remaining)}</span
                  >
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600">Status:</span>
                  <span class="font-medium capitalize"
                    >{billing_cycle.payment_status}</span
                  >
                </div>
              </div>
            </div>

            <!-- Changes Summary -->
            {#if hasChanges}
              <div class="bg-yellow-50 p-4 rounded-lg">
                <h4 class="font-medium text-yellow-800 mb-2">
                  Changes to Save
                </h4>
                <ul class="text-sm text-yellow-700 space-y-1">
                  {#if form.due_date !== billing_cycle.due_date}
                    <li>• Due date will change</li>
                  {/if}
                  {#if parseFloat(form.total_amount) !== parseFloat(billing_cycle.total_amount)}
                    <li>• Total amount will change</li>
                  {/if}
                </ul>
              </div>
            {/if}

            <!-- Validation Status -->
            {#if !isFormValid}
              <div class="bg-red-50 p-4 rounded-lg">
                <h4 class="font-medium text-red-800 mb-2">Required Fields</h4>
                <ul class="text-sm text-red-700 space-y-1">
                  {#if !form.due_date}
                    <li>• Due date is required</li>
                  {/if}
                  {#if !form.total_amount || parseFloat(form.total_amount) <= 0}
                    <li>• Valid total amount is required</li>
                  {/if}
                </ul>
              </div>
            {/if}
          </CardContent>
        </Card>
      </div>
    </div>
  </div>
</Layout>
