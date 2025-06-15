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
  import { Badge } from "$lib/components/ui/badge";
  import { Separator } from "$lib/components/ui/separator";
  import {
    ArrowLeft,
    Edit,
    Trash2,
    Calendar,
    DollarSign,
    Users,
    AlertTriangle,
    ExternalLink,
    CreditCard,
    Clock,
    UserPlus,
    Settings,
  } from "lucide-svelte";
  import InviteForm from "../../components/invitations/InviteForm.svelte";

  export let project;

  function formatCurrency(amount) {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
    }).format(amount);
  }

  function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  }

  function formatDateTime(dateString) {
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  }

  function getBillingCycleBadgeVariant(cycle) {
    switch (cycle) {
      case "monthly":
        return "default";
      case "quarterly":
        return "secondary";
      case "yearly":
        return "outline";
      default:
        return "default";
    }
  }

  function getStatusBadgeVariant(project) {
    if (!project.active) return "destructive";
    if (project.expiring_soon) return "warning";
    return "success";
  }

  function getStatusText(project) {
    if (!project.active) return "Expired";
    if (project.expiring_soon)
      return `Expires in ${project.days_until_renewal} days`;
    return "Active";
  }

  function goBack() {
    router.get("/dashboard");
  }

  function editProject() {
    router.get(`/projects/${project.id}/edit`);
  }

  function deleteProject() {
    if (
      confirm(
        "Are you sure you want to delete this project? This action cannot be undone.",
      )
    ) {
      router.delete(`/projects/${project.id}`);
    }
  }

  function openSubscriptionUrl() {
    if (project.subscription_url) {
      window.open(project.subscription_url, "_blank");
    }
  }

  function manageInvitations() {
    router.get(`/projects/${project.id}/invitations`);
  }
</script>

<svelte:head>
  <title>{project.name} - SplitSub</title>
</svelte:head>

<Layout>
  <div class="mx-auto max-w-7xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
    <!-- Header -->
    <div
      class="flex flex-col sm:flex-row sm:items-center justify-between mb-6 sm:mb-8 gap-4 sm:gap-0"
    >
      <div class="flex items-center gap-4">
        <button
          type="button"
          on:click={goBack}
          class="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-muted-foreground hover:text-foreground hover:bg-accent hover:bg-opacity-50 rounded-md transition-colors cursor-pointer"
        >
          <ArrowLeft class="h-4 w-4" />
          <span class="hidden sm:inline">Back to Projects</span>
          <span class="sm:hidden">Back</span>
        </button>
      </div>

      {#if project.is_owner}
        <div class="flex items-center gap-2 flex-wrap">
          <button
            type="button"
            on:click={editProject}
            class="inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-xs font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-accent hover:text-accent-foreground shadow-sm h-8 px-3 cursor-pointer"
          >
            <Edit class="h-4 w-4" />
            Edit
          </button>
          <button
            type="button"
            on:click={deleteProject}
            class="inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-xs font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 bg-destructive text-destructive-foreground hover:bg-destructive/90 shadow-sm h-8 px-3 cursor-pointer"
          >
            <Trash2 class="h-4 w-4" />
            Delete
          </button>
        </div>
      {/if}
    </div>

    <!-- Project Header -->
    <div class="mb-6 sm:mb-8">
      <div
        class="flex flex-col sm:flex-row sm:items-start justify-between mb-4 gap-3 sm:gap-0"
      >
        <div class="flex-1">
          <h1 class="text-2xl sm:text-3xl font-bold tracking-tight mb-2">
            {project.name}
          </h1>
          {#if project.description}
            <p class="text-muted-foreground text-base sm:text-lg">
              {project.description}
            </p>
          {/if}
        </div>
        <Badge
          variant={getStatusBadgeVariant(project)}
          class="text-sm self-start"
        >
          {getStatusText(project)}
        </Badge>
      </div>

      <div class="flex flex-wrap items-center gap-2">
        {#if project.subscription_url}
          <button
            type="button"
            on:click={openSubscriptionUrl}
            class="inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-xs font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-accent hover:text-accent-foreground shadow-sm h-8 px-3 cursor-pointer"
          >
            <ExternalLink class="h-4 w-4" />
            <span class="hidden sm:inline">Open Subscription</span>
            <span class="sm:hidden">Open</span>
          </button>
        {/if}

        {#if project.is_owner}
          <InviteForm {project} />
          <button
            type="button"
            on:click={manageInvitations}
            class="inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-xs font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-accent hover:text-accent-foreground shadow-sm h-8 px-3 cursor-pointer"
          >
            <Settings class="h-4 w-4" />
            <span class="hidden sm:inline">Manage Invitations</span>
            <span class="sm:hidden">Invites</span>
          </button>
          <button
            type="button"
            on:click={() =>
              router.visit(`/projects/${project.id}/payment_confirmations`)}
            class="inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-xs font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-accent hover:text-accent-foreground shadow-sm h-8 px-3 cursor-pointer"
          >
            <CreditCard class="h-4 w-4" />
            <span class="hidden sm:inline">Payment Confirmations</span>
            <span class="sm:hidden">Payments</span>
          </button>
          <button
            type="button"
            on:click={() =>
              router.visit(`/projects/${project.id}/billing_cycles`)}
            class="inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-xs font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-accent hover:text-accent-foreground shadow-sm h-8 px-3 cursor-pointer"
          >
            <Calendar class="h-4 w-4" />
            <span class="hidden sm:inline">Billing Cycles</span>
            <span class="sm:hidden">Cycles</span>
          </button>
        {/if}
      </div>
    </div>

    <div class="grid gap-6 lg:grid-cols-2">
      <!-- Billing Information -->
      <Card>
        <CardHeader>
          <CardTitle class="flex items-center gap-2">
            <CreditCard class="h-5 w-5" />
            Billing Information
          </CardTitle>
        </CardHeader>
        <CardContent class="space-y-4">
          <div class="flex items-center justify-between">
            <span class="text-muted-foreground">Total Cost</span>
            <span class="text-2xl font-bold"
              >{formatCurrency(project.cost)}</span
            >
          </div>

          <div class="flex items-center justify-between">
            <span class="text-muted-foreground">Billing Cycle</span>
            <Badge variant={getBillingCycleBadgeVariant(project.billing_cycle)}>
              {project.billing_cycle}
            </Badge>
          </div>

          <div class="flex items-center justify-between">
            <span class="text-muted-foreground">Cost per Member</span>
            <span class="text-lg font-semibold"
              >{formatCurrency(project.cost_per_member)}</span
            >
          </div>

          <Separator />

          <div class="flex items-center justify-between">
            <span class="text-muted-foreground">Next Renewal</span>
            <span class="font-medium">{formatDate(project.renewal_date)}</span>
          </div>

          <div class="flex items-center justify-between">
            <span class="text-muted-foreground">Days Until Renewal</span>
            <span class="font-medium">{project.days_until_renewal} days</span>
          </div>

          <div class="flex items-center justify-between">
            <span class="text-muted-foreground">Reminder</span>
            <span class="font-medium">{project.reminder_days} days before</span>
          </div>

          {#if project.expiring_soon}
            <div
              class="flex items-center gap-2 text-sm text-amber-600 bg-amber-50 p-3 rounded-lg"
            >
              <AlertTriangle class="h-4 w-4" />
              <span
                >Renewal reminder will be sent in {project.reminder_days} days</span
              >
            </div>
          {/if}
        </CardContent>
      </Card>

      <!-- Members -->
      <Card>
        <CardHeader>
          <CardTitle class="flex items-center gap-2">
            <Users class="h-5 w-5" />
            Members ({project.total_members})
          </CardTitle>
        </CardHeader>
        <CardContent class="space-y-4">
          <!-- Owner -->
          <div
            class="flex items-center justify-between p-3 bg-muted rounded-lg"
          >
            <div>
              <p class="font-medium">{project.owner.name}</p>
              <p class="text-sm text-muted-foreground">{project.owner.email}</p>
            </div>
            <Badge variant="secondary">Owner</Badge>
          </div>

          <!-- Members -->
          {#if project.members.length > 0}
            {#each project.members as member}
              <div
                class="flex items-center justify-between p-3 border rounded-lg"
              >
                <div>
                  <p class="font-medium">{member.name}</p>
                  <p class="text-sm text-muted-foreground">{member.email}</p>
                </div>
                <Badge variant="outline">Member</Badge>
              </div>
            {/each}
          {:else}
            <div class="text-center py-4 text-muted-foreground">
              <Users class="h-8 w-8 mx-auto mb-2 opacity-50" />
              <p>No additional members yet</p>
              <p class="text-sm">Invite others to split the cost</p>
            </div>
          {/if}
        </CardContent>
      </Card>

      <!-- Payment Instructions -->
      {#if project.payment_instructions}
        <Card class="lg:col-span-2">
          <CardHeader>
            <CardTitle class="flex items-center gap-2">
              <DollarSign class="h-5 w-5" />
              Payment Instructions
            </CardTitle>
            <CardDescription>How members should pay their share</CardDescription
            >
          </CardHeader>
          <CardContent>
            <div class="prose prose-sm max-w-none">
              <p class="whitespace-pre-wrap">{project.payment_instructions}</p>
            </div>
          </CardContent>
        </Card>
      {/if}

      <!-- Project Details -->
      <Card class="lg:col-span-2">
        <CardHeader>
          <CardTitle class="flex items-center gap-2">
            <Clock class="h-5 w-5" />
            Project Details
          </CardTitle>
        </CardHeader>
        <CardContent class="space-y-4">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <span class="text-muted-foreground text-sm">Created</span>
              <p class="font-medium">{formatDateTime(project.created_at)}</p>
            </div>
            <div>
              <span class="text-muted-foreground text-sm">Last Updated</span>
              <p class="font-medium">{formatDateTime(project.updated_at)}</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  </div>
</Layout>
