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
  let email = user_email || ""; // Use invitation email or empty string
  let isSubmitting = false;
  let emailError = "";

  // Check if this is a link-only invitation (no email provided)
  $: isLinkOnlyInvitation = !user_email;

  function validateEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  function isFormValid() {
    // Pure validation function - no state mutations
    const hasFirstName = firstName.trim();
    const hasLastName = lastName.trim();
    const hasValidEmail = isLinkOnlyInvitation
      ? email.trim() && validateEmail(email.trim())
      : true;

    return hasFirstName && hasLastName && hasValidEmail;
  }

  function validateAndSetErrors() {
    // Separate function for setting errors - only call from event handlers
    emailError = "";

    if (isLinkOnlyInvitation && email.trim() && !validateEmail(email.trim())) {
      emailError = "Please enter a valid email address";
      return false;
    }

    if (isLinkOnlyInvitation && !email.trim()) {
      emailError = "Email address is required";
      return false;
    }

    return isFormValid();
  }

  function confirmAcceptance() {
    if (!validateAndSetErrors()) {
      return;
    }

    isSubmitting = true;

    router.post(
      `/invitations/${invitation.token}/confirm`,
      {
        first_name: firstName.trim(),
        last_name: lastName.trim(),
        email: isLinkOnlyInvitation ? email.trim() : undefined, // Only send email for link-only invitations
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

  function handleEmailInput() {
    if (emailError && email.trim()) {
      emailError = "";
    }
  }
</script>

<svelte:head>
  <title>Confirm Invitation - {project.name} - SplitSub</title>
</svelte:head>

<div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
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
  <div class="mx-auto max-w-2xl">
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
          {#if isLinkOnlyInvitation}
            <!-- Allow email input for link-only invitations -->
            <Input
              id="email"
              type="email"
              bind:value={email}
              on:input={handleEmailInput}
              placeholder="Enter your email address"
              required
              class={emailError ? "border-red-500" : ""}
            />
            {#if emailError}
              <p class="text-sm text-red-600">{emailError}</p>
            {/if}
            <p class="text-sm text-muted-foreground">
              This will be your account email address
            </p>
          {:else}
            <!-- Show fixed email for email-specific invitations -->
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
          {/if}
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
            disabled={isSubmitting || !isFormValid()}
          >
            <CheckCircle class="h-4 w-4 mr-2" />
            {isSubmitting ? "Creating Account..." : "Join Project"}
          </button>
        </div>
      </CardContent>
    </Card>
  </div>
</div>
