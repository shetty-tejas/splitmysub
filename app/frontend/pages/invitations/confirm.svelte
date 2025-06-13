<script>
  import { router } from "@inertiajs/svelte";
  import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
  } from "$lib/components/ui/card";

  import { Input } from "$lib/components/ui/input";
  import { Label } from "$lib/components/ui/label";
  import { Separator } from "$lib/components/ui/separator";
  import { CheckCircle, Mail, ArrowLeft } from "lucide-svelte";

  export let invitation;
  export let project;
  export let user_email;

  let firstName = "";
  let lastName = "";
  let isSubmitting = false;

  function confirmAcceptance() {
    if (!firstName.trim() || !lastName.trim()) {
      // Form validation is already handled by the disabled state
      return;
    }

    isSubmitting = true;

    router.post(
      `/invitations/${invitation.token}/confirm`,
      {
        first_name: firstName.trim(),
        last_name: lastName.trim(),
      },
      {
        onSuccess: () => {
          // Will redirect automatically from controller
        },
        onError: (errors) => {
          console.error("Error confirming invitation:", errors);
          isSubmitting = false;
        },
      },
    );
  }

  function goBack() {
    router.get(`/invitations/${invitation.token}`);
  }
</script>

<svelte:head>
  <title>Confirm Invitation - {project.name} - SplitSub</title>
</svelte:head>

<div class="container mx-auto px-4 py-8 max-w-2xl">
  <!-- Header -->
  <div class="text-center mb-8">
    <div class="mb-4">
      <div class="text-2xl font-bold text-blue-600 mb-2">SplitSub</div>
      <p class="text-muted-foreground">Subscription Cost Sharing Made Simple</p>
    </div>

    <h1 class="text-3xl font-bold tracking-tight mb-2">Almost There!</h1>
    <p class="text-lg text-muted-foreground">
      Please confirm your details to join {project.name}
    </p>
  </div>

  <!-- User Details Form -->
  <Card>
    <CardHeader>
      <CardTitle class="flex items-center gap-2">
        <Mail class="h-5 w-5" />
        Your Details
      </CardTitle>
      <CardDescription>
        We'll create your account with these details
      </CardDescription>
    </CardHeader>
    <CardContent class="space-y-4">
      <div class="space-y-2">
        <Label for="email">Email Address</Label>
        <Input
          id="email"
          type="email"
          value={user_email}
          disabled
          class="bg-muted"
        />
        <p class="text-sm text-muted-foreground">
          This email was invited to join the project
        </p>
      </div>

      <div class="grid grid-cols-2 gap-4">
        <div class="space-y-2">
          <Label for="firstName">First Name</Label>
          <Input
            id="firstName"
            type="text"
            bind:value={firstName}
            placeholder="Enter your first name"
            required
          />
        </div>
        <div class="space-y-2">
          <Label for="lastName">Last Name</Label>
          <Input
            id="lastName"
            type="text"
            bind:value={lastName}
            placeholder="Enter your last name"
            required
          />
        </div>
      </div>

      <Separator />

      <div class="flex gap-3">
        <button
          type="button"
          class="flex-1 h-9 px-4 py-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground shadow-sm rounded-md text-sm font-medium transition-colors inline-flex items-center justify-center gap-2 cursor-pointer disabled:pointer-events-none disabled:opacity-50"
          on:click={goBack}
          disabled={isSubmitting}
        >
          <ArrowLeft class="h-4 w-4 mr-2" />
          Back
        </button>
        <button
          type="button"
          class="flex-1 h-9 px-4 py-2 bg-primary text-primary-foreground hover:bg-primary/90 shadow rounded-md text-sm font-medium transition-colors inline-flex items-center justify-center gap-2 cursor-pointer disabled:pointer-events-none disabled:opacity-50"
          on:click={confirmAcceptance}
          disabled={isSubmitting || !firstName.trim() || !lastName.trim()}
        >
          <CheckCircle class="h-4 w-4 mr-2" />
          {isSubmitting ? "Creating Account..." : "Join Project"}
        </button>
      </div>
    </CardContent>
  </Card>
</div>
