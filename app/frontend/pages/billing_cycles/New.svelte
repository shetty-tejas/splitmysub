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
    total_amount: billing_cycle.total_amount || project.cost || "",
  };

  let isSubmitting = false;

  function handleSubmit() {
    if (isSubmitting) return;

    isSubmitting = true;
    router.post(
      `/projects/${project.id}/billing_cycles`,
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

  // Set minimum date to today
  $: minDate = new Date().toISOString().split("T")[0];
</script>

<svelte:head>
  <title>New Billing Cycle - {project.name}</title>
</svelte:head>

<Layout>
  <div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
    <!-- Header -->
    <div class="flex items-center justify-between mb-8">
      <div class="flex items-center gap-4">
        <a
          href="/projects/{project.id}/billing_cycles"
          class="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-muted-foreground hover:text-foreground hover:bg-accent hover:bg-opacity-50 rounded-md transition-colors cursor-pointer"
        >
          <ArrowLeft class="h-4 w-4" />
          Back to Billing Cycles
        </a>
      </div>
    </div>

    <!-- Project Header -->
    <div class="mb-8">
      <h1 class="text-3xl font-bold tracking-tight mb-2">
        Create New Billing Cycle
      </h1>
      <p class="text-muted-foreground text-lg">
        <strong>{project.name}</strong>
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
            <form on:submit|preventDefault={handleSubmit} class="space-y-6">
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
                  min={minDate}
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

              <!-- Submit Button -->
              <div class="flex gap-4 pt-4">
                <Button
                  type="submit"
                  disabled={!isFormValid || isSubmitting}
                  class="flex-1 sm:flex-none"
                >
                  <Save class="w-4 h-4 mr-2" />
                  {isSubmitting ? "Creating..." : "Create Billing Cycle"}
                </Button>
                <Button
                  href="/projects/{project.id}/billing_cycles"
                  variant="outline"
                  disabled={isSubmitting}
                >
                  Cancel
                </Button>
              </div>
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
              Preview
            </CardTitle>
          </CardHeader>
          <CardContent class="space-y-4">
            <!-- Project Info -->
            <div class="bg-gray-50 p-4 rounded-lg">
              <h4 class="font-medium text-gray-900 mb-2">Project Details</h4>
              <div class="space-y-2 text-sm">
                <div class="flex justify-between">
                  <span class="text-gray-600">Name:</span>
                  <span class="font-medium">{project.name}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600">Billing Cycle:</span>
                  <span class="font-medium capitalize"
                    >{project.billing_cycle}</span
                  >
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600">Total Members:</span>
                  <span class="font-medium">{project.total_members}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600">Default Cost:</span>
                  <span class="font-medium">{formatCurrency(project.cost)}</span
                  >
                </div>
              </div>
            </div>

            <!-- Billing Cycle Preview -->
            <div class="bg-blue-50 p-4 rounded-lg">
              <h4 class="font-medium text-gray-900 mb-2">
                Billing Cycle Preview
              </h4>
              <div class="space-y-2 text-sm">
                <div class="flex justify-between">
                  <span class="text-gray-600">Due Date:</span>
                  <span class="font-medium">
                    {form.due_date ? formatDate(form.due_date) : "Not set"}
                  </span>
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600">Total Amount:</span>
                  <span class="font-medium text-lg">
                    {form.total_amount
                      ? formatCurrency(parseFloat(form.total_amount))
                      : "$0.00"}
                  </span>
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600">Per Member:</span>
                  <span class="font-medium">
                    {perMemberAmount > 0
                      ? formatCurrency(perMemberAmount)
                      : "$0.00"}
                  </span>
                </div>
              </div>
            </div>

            <!-- Next Steps -->
            <div class="bg-green-50 p-4 rounded-lg">
              <h4 class="font-medium text-gray-900 mb-2">What happens next?</h4>
              <ul class="text-sm text-gray-700 space-y-1">
                <li>• Billing cycle will be created</li>
                <li>• Payment reminders will be scheduled</li>
                <li>• Members will be notified</li>
                <li>• You can track payment progress</li>
              </ul>
            </div>

            <!-- Validation Status -->
            {#if !isFormValid}
              <div class="bg-yellow-50 p-4 rounded-lg">
                <h4 class="font-medium text-yellow-800 mb-2">
                  Required Fields
                </h4>
                <ul class="text-sm text-yellow-700 space-y-1">
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
