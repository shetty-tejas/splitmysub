<script>
  import { router } from "@inertiajs/svelte";
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
    CheckCircle,
    XCircle,
    Mail,
    Calendar,
    DollarSign,
    Users,
    Clock,
    AlertTriangle,
  } from "lucide-svelte";

  export let invitation;
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

  function acceptInvitation() {
    router.post(
      `/invitations/${invitation.token}/accept`,
      {},
      {
        onSuccess: () => {
          // Will redirect automatically from controller
        },
        onError: (errors) => {
          console.error("Error accepting invitation:", errors);
          // Error handling could be improved with a toast notification system
        },
      },
    );
  }

  function declineInvitation() {
    if (confirm("Are you sure you want to decline this invitation?")) {
      router.post(
        `/invitations/${invitation.token}/decline`,
        {},
        {
          onSuccess: () => {
            // Will redirect automatically from controller
          },
          onError: (errors) => {
            console.error("Error declining invitation:", errors);
          },
        },
      );
    }
  }

  function isExpiringSoon() {
    const expiresAt = new Date(invitation.expires_at);
    const now = new Date();
    const hoursUntilExpiry = (expiresAt - now) / (1000 * 60 * 60);
    return hoursUntilExpiry <= 24;
  }
</script>

<svelte:head>
  <title>Invitation to {project.name} - SplitSub</title>
</svelte:head>

<div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
  <!-- Header -->
  <div class="text-center mb-8">
    <div class="mb-4">
      <div class="text-2xl font-bold text-blue-600 mb-2">SplitSub</div>
      <p class="text-muted-foreground">Subscription Cost Sharing Made Simple</p>
    </div>

    <h1 class="text-3xl font-bold tracking-tight mb-2">You're Invited!</h1>
    <p class="text-lg text-muted-foreground">
      {invitation.invited_by.name || invitation.invited_by.email} has invited you
      to join their subscription project
    </p>
  </div>

  <!-- Invitation Status Warning -->
  {#if isExpiringSoon()}
    <div class="mb-6">
      <div
        class="flex items-center gap-2 text-sm text-amber-600 bg-amber-50 p-4 rounded-lg border border-amber-200"
      >
        <AlertTriangle class="h-4 w-4" />
        <span>
          This invitation expires on {formatDateTime(invitation.expires_at)}.
          Please accept or decline soon!
        </span>
      </div>
    </div>
  {/if}

  <div class="grid gap-6 lg:grid-cols-2">
    <!-- Project Information -->
    <Card>
      <CardHeader>
        <CardTitle class="flex items-center gap-2">
          <DollarSign class="h-5 w-5" />
          Project Details
        </CardTitle>
        <CardDescription>
          Information about the subscription you're being invited to join
        </CardDescription>
      </CardHeader>
      <CardContent class="space-y-4">
        <div>
          <h3 class="text-xl font-semibold mb-2">{project.name}</h3>
          {#if project.description}
            <p class="text-muted-foreground">{project.description}</p>
          {/if}
        </div>

        <Separator />

        <div class="space-y-3">
          <div class="flex items-center justify-between">
            <span class="text-muted-foreground">Total Cost</span>
            <span class="text-lg font-semibold"
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
            <span class="text-muted-foreground">Your Share</span>
            <span class="text-xl font-bold text-green-600">
              {formatCurrency(project.cost_per_member)}
            </span>
          </div>

          <div class="flex items-center justify-between">
            <span class="text-muted-foreground">Next Renewal</span>
            <span class="font-medium">{formatDate(project.renewal_date)}</span>
          </div>

          <div class="flex items-center justify-between">
            <span class="text-muted-foreground">Your Role</span>
            <Badge variant="outline">{invitation.role}</Badge>
          </div>
        </div>
      </CardContent>
    </Card>

    <!-- Invitation Details -->
    <Card>
      <CardHeader>
        <CardTitle class="flex items-center gap-2">
          <Mail class="h-5 w-5" />
          Invitation Details
        </CardTitle>
      </CardHeader>
      <CardContent class="space-y-4">
        <div class="flex items-center justify-between p-3 bg-muted rounded-lg">
          <div>
            <p class="font-medium">
              {invitation.invited_by.name || invitation.invited_by.email}
            </p>
            <p class="text-sm text-muted-foreground">
              {invitation.invited_by.email}
            </p>
          </div>
          <Badge variant="secondary">Invited by</Badge>
        </div>

        <div class="space-y-3">
          <div class="flex items-center justify-between">
            <span class="text-muted-foreground">Invited to</span>
            <span class="font-medium">{invitation.email}</span>
          </div>

          <div class="flex items-center justify-between">
            <span class="text-muted-foreground">Invitation expires</span>
            <span class="font-medium"
              >{formatDateTime(invitation.expires_at)}</span
            >
          </div>
        </div>

        <Separator />

        <!-- Action Buttons -->
        <div class="space-y-3">
          <button
            class="w-full h-10 px-8 bg-primary text-primary-foreground hover:bg-primary/90 shadow rounded-md text-sm font-medium transition-colors inline-flex items-center justify-center gap-2 cursor-pointer"
            on:click={acceptInvitation}
          >
            <CheckCircle class="h-4 w-4 mr-2" />
            Accept Invitation
          </button>

          <button
            class="w-full h-9 px-4 py-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground shadow-sm rounded-md text-sm font-medium transition-colors inline-flex items-center justify-center gap-2 cursor-pointer"
            on:click={declineInvitation}
          >
            <XCircle class="h-4 w-4 mr-2" />
            Decline Invitation
          </button>
        </div>
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
          <CardDescription>How to pay your share once you join</CardDescription>
        </CardHeader>
        <CardContent>
          <div class="prose prose-sm max-w-none">
            <p class="whitespace-pre-wrap">{project.payment_instructions}</p>
          </div>
        </CardContent>
      </Card>
    {/if}

    <!-- What Happens Next -->
    <Card class="lg:col-span-2">
      <CardHeader>
        <CardTitle class="flex items-center gap-2">
          <Clock class="h-5 w-5" />
          What Happens Next?
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div class="grid md:grid-cols-2 gap-4">
          <div class="space-y-3">
            <h4 class="font-medium">If you accept:</h4>
            <ul class="text-sm text-muted-foreground space-y-1">
              <li>• You'll become a member of this project</li>
              <li>• You can view project details and payment history</li>
              <li>• You'll receive payment reminders before renewals</li>
              <li>• You can upload payment evidence when needed</li>
            </ul>
          </div>
          <div class="space-y-3">
            <h4 class="font-medium">If you decline:</h4>
            <ul class="text-sm text-muted-foreground space-y-1">
              <li>• You won't be added to the project</li>
              <li>• The invitation will be marked as declined</li>
              <li>• You won't receive any further notifications</li>
              <li>• The project owner will be notified</li>
            </ul>
          </div>
        </div>
      </CardContent>
    </Card>
  </div>
</div>
