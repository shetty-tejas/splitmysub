<script>
  import { page } from "@inertiajs/svelte";
  import { router } from "@inertiajs/svelte";
  import Layout from "../../layouts/layout.svelte";
  import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
  } from "$lib/components/ui/card";
  import { Button } from "$lib/components/ui/button";
  import { Input } from "$lib/components/ui/input";
  import { Label } from "$lib/components/ui/label";
  import { Textarea } from "$lib/components/ui/textarea";

  import { ArrowLeft, Save } from "lucide-svelte";

  let form = {
    name: "",
    description: "",
    cost: "",
    billing_cycle: "",
    renewal_date: "",
    reminder_days: "7",
    payment_instructions: "",
    subscription_url: "",
  };

  let errors = $page.props.errors || {};
  let isSubmitting = false;

  function handleSubmit() {
    if (isSubmitting) return;

    isSubmitting = true;

    router.post(
      "/projects",
      { project: form },
      {
        onFinish: () => {
          isSubmitting = false;
        },
        onError: (errors) => {
          console.error("Form errors:", errors);
        },
      },
    );
  }

  function goBack() {
    router.get("/projects");
  }

  // Set default renewal date to 1 month from now
  function setDefaultRenewalDate() {
    if (!form.renewal_date) {
      const nextMonth = new Date();
      nextMonth.setMonth(nextMonth.getMonth() + 1);
      form.renewal_date = nextMonth.toISOString().split("T")[0];
    }
  }

  // Update renewal date when billing cycle changes
  function updateRenewalDate() {
    if (form.billing_cycle) {
      const now = new Date();
      let renewalDate = new Date();

      switch (form.billing_cycle) {
        case "monthly":
          renewalDate.setMonth(now.getMonth() + 1);
          break;
        case "quarterly":
          renewalDate.setMonth(now.getMonth() + 3);
          break;
        case "yearly":
          renewalDate.setFullYear(now.getFullYear() + 1);
          break;
      }

      form.renewal_date = renewalDate.toISOString().split("T")[0];
    }
  }

  // Initialize default renewal date
  setDefaultRenewalDate();
</script>

<svelte:head>
  <title>New Project - SplitSub</title>
</svelte:head>

<Layout>
  <div class="container mx-auto px-4 py-8 max-w-2xl">
    <div class="flex items-center gap-4 mb-8">
      <button
        type="button"
        on:click={goBack}
        class="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-muted-foreground hover:text-foreground hover:bg-accent hover:bg-opacity-50 rounded-md transition-colors cursor-pointer"
      >
        <ArrowLeft class="h-4 w-4" />
        Back to Projects
      </button>
    </div>

    <Card>
      <CardHeader>
        <CardTitle class="text-2xl">Create New Project</CardTitle>
        <CardDescription>
          Set up a new subscription project to split costs with others
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form on:submit|preventDefault={handleSubmit} class="space-y-6">
          <!-- Basic Information -->
          <div class="space-y-4">
            <h3 class="text-lg font-semibold">Basic Information</h3>

            <div class="space-y-2">
              <Label for="name">Project Name *</Label>
              <Input
                id="name"
                bind:value={form.name}
                placeholder="e.g., Netflix Family Plan"
                class={errors.name ? "border-destructive" : ""}
              />
              {#if errors.name}
                <p class="text-sm text-destructive">{errors.name[0]}</p>
              {/if}
            </div>

            <div class="space-y-2">
              <Label for="description">Description</Label>
              <Textarea
                id="description"
                bind:value={form.description}
                placeholder="Optional description of the subscription service"
                rows="3"
                class={errors.description ? "border-destructive" : ""}
              />
              {#if errors.description}
                <p class="text-sm text-destructive">{errors.description[0]}</p>
              {/if}
            </div>

            <div class="space-y-2">
              <Label for="subscription_url">Subscription URL</Label>
              <Input
                id="subscription_url"
                bind:value={form.subscription_url}
                placeholder="https://netflix.com/account"
                type="url"
                class={errors.subscription_url ? "border-destructive" : ""}
              />
              {#if errors.subscription_url}
                <p class="text-sm text-destructive">
                  {errors.subscription_url[0]}
                </p>
              {/if}
            </div>
          </div>

          <!-- Billing Information -->
          <div class="space-y-4">
            <h3 class="text-lg font-semibold">Billing Information</h3>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="space-y-2">
                <Label for="cost">Total Cost *</Label>
                <Input
                  id="cost"
                  bind:value={form.cost}
                  placeholder="15.99"
                  type="number"
                  step="0.01"
                  min="0"
                  class={errors.cost ? "border-destructive" : ""}
                />
                {#if errors.cost}
                  <p class="text-sm text-destructive">{errors.cost[0]}</p>
                {/if}
              </div>

              <div class="space-y-2">
                <Label for="billing_cycle">Billing Cycle *</Label>
                <select
                  id="billing_cycle"
                  bind:value={form.billing_cycle}
                  on:change={updateRenewalDate}
                  class="flex h-9 w-full items-center justify-between whitespace-nowrap rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50 {errors.billing_cycle
                    ? 'border-destructive'
                    : ''}"
                >
                  <option value="">Select billing cycle</option>
                  <option value="monthly">Monthly</option>
                  <option value="quarterly">Quarterly</option>
                  <option value="yearly">Yearly</option>
                </select>
                {#if errors.billing_cycle}
                  <p class="text-sm text-destructive">
                    {errors.billing_cycle[0]}
                  </p>
                {/if}
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="space-y-2">
                <Label for="renewal_date">Next Renewal Date *</Label>
                <Input
                  id="renewal_date"
                  bind:value={form.renewal_date}
                  type="date"
                  class={errors.renewal_date ? "border-destructive" : ""}
                />
                {#if errors.renewal_date}
                  <p class="text-sm text-destructive">
                    {errors.renewal_date[0]}
                  </p>
                {/if}
              </div>

              <div class="space-y-2">
                <Label for="reminder_days">Reminder Days Before *</Label>
                <Input
                  id="reminder_days"
                  bind:value={form.reminder_days}
                  type="number"
                  min="1"
                  max="30"
                  class={errors.reminder_days ? "border-destructive" : ""}
                />
                {#if errors.reminder_days}
                  <p class="text-sm text-destructive">
                    {errors.reminder_days[0]}
                  </p>
                {/if}
              </div>
            </div>
          </div>

          <!-- Payment Instructions -->
          <div class="space-y-4">
            <h3 class="text-lg font-semibold">Payment Instructions</h3>

            <div class="space-y-2">
              <Label for="payment_instructions">Payment Instructions</Label>
              <Textarea
                id="payment_instructions"
                bind:value={form.payment_instructions}
                placeholder="How should members pay you? Include payment methods, account details, etc."
                rows="4"
                class={errors.payment_instructions ? "border-destructive" : ""}
              />
              {#if errors.payment_instructions}
                <p class="text-sm text-destructive">
                  {errors.payment_instructions[0]}
                </p>
              {/if}
              <p class="text-sm text-muted-foreground">
                This will be shared with project members when they need to pay
                their share.
              </p>
            </div>
          </div>

          <!-- Submit Button -->
          <div class="flex justify-end gap-4 pt-6">
            <button
              type="button"
              on:click={goBack}
              class="inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-accent hover:text-accent-foreground shadow-sm h-9 px-4 py-2 cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              class="inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 bg-primary text-primary-foreground hover:bg-primary/90 shadow h-9 px-4 py-2 cursor-pointer"
            >
              {#if isSubmitting}
                <div
                  class="animate-spin rounded-full h-4 w-4 border-b-2 border-white"
                ></div>
              {:else}
                <Save class="h-4 w-4" />
              {/if}
              Create Project
            </button>
          </div>
        </form>
      </CardContent>
    </Card>
  </div>
</Layout>
