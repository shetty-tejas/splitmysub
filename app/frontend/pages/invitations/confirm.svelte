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
  import { CheckCircle, Mail, ArrowLeft } from "@lucide/svelte";
  import { toast } from "svelte-sonner";

  export let invitation;
  export let project;
  export let user_email;
  export let errors = {};

  let firstName = "";
  let lastName = "";
  let email = user_email || ""; // Use invitation email or empty string
  let isSubmitting = false;
  let emailError = "";
  let firstNameError = "";
  let lastNameError = "";
  let generalError = "";

  // Set initial errors from server
  $: {
    if (errors.first_name) {
      firstNameError = Array.isArray(errors.first_name)
        ? errors.first_name[0]
        : errors.first_name;
    }
    if (errors.last_name) {
      lastNameError = Array.isArray(errors.last_name)
        ? errors.last_name[0]
        : errors.last_name;
    }
    if (errors.email) {
      emailError = Array.isArray(errors.email) ? errors.email[0] : errors.email;
    }
    if (errors.message) {
      generalError = errors.message;
      toast.error(errors.message);
    }
  }

  // Check if this is a link-only invitation (no email provided)
  $: isLinkOnlyInvitation = !user_email;

  // Reactive form validation - only validate email on client side
  $: formIsValid = isLinkOnlyInvitation
    ? email.trim().length > 0 && validateEmail(email.trim())
    : true;

  function validateEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  function isFormValid() {
    const hasFirstName = firstName.trim().length > 0;
    const hasLastName = lastName.trim().length > 0;
    const hasValidEmail = isLinkOnlyInvitation
      ? email.trim().length > 0 && validateEmail(email.trim())
      : true;

    return hasFirstName && hasLastName && hasValidEmail;
  }

  function validateAndSetErrors() {
    // Only validate email on client side
    emailError = "";

    if (isLinkOnlyInvitation && email.trim() && !validateEmail(email.trim())) {
      emailError = "Please enter a valid email address";
      return false;
    }

    if (isLinkOnlyInvitation && !email.trim()) {
      emailError = "Email address is required";
      return false;
    }

    return true; // Always return true since we only validate email now
  }

  function confirmAcceptance() {
    if (!validateAndSetErrors()) {
      return;
    }

    // Clear previous errors
    firstNameError = "";
    lastNameError = "";
    generalError = "";
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

          // Handle validation errors
          if (errors.first_name) {
            firstNameError = Array.isArray(errors.first_name)
              ? errors.first_name[0]
              : errors.first_name;
          }
          if (errors.last_name) {
            lastNameError = Array.isArray(errors.last_name)
              ? errors.last_name[0]
              : errors.last_name;
          }
          if (errors.email) {
            emailError = Array.isArray(errors.email)
              ? errors.email[0]
              : errors.email;
          }

          // Handle general errors
          if (errors.message || errors.error) {
            generalError = errors.message || errors.error;
            toast.error(generalError);
          }
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
  <title>Confirm Invitation - {project.name} - SplitMySub</title>
</svelte:head>

<div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
  <!-- Header -->
  <div class="text-center mb-8">
    <div class="mb-4">
      <div class="text-2xl font-bold text-blue-600 mb-2">SplitMySub</div>
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
        {#if generalError}
          <div class="bg-red-50 border border-red-200 rounded-md p-3">
            <p class="text-sm text-red-600">{generalError}</p>
          </div>
        {/if}

        <div class="space-y-2">
          <Label for="email">Email Address</Label>
          {#if isLinkOnlyInvitation}
            <!-- Allow email input for link-only invitations -->
            <Input
              id="email"
              type="email"
              bind:value={email}
              oninput={handleEmailInput}
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
              class={firstNameError ? "border-red-500" : ""}
            />
            {#if firstNameError}
              <p class="text-sm text-red-600">{firstNameError}</p>
            {/if}
          </div>
          <div class="space-y-2">
            <Label for="lastName">Last Name</Label>
            <Input
              id="lastName"
              type="text"
              bind:value={lastName}
              placeholder="Enter your last name"
              required
              class={lastNameError ? "border-red-500" : ""}
            />
            {#if lastNameError}
              <p class="text-sm text-red-600">{lastNameError}</p>
            {/if}
          </div>
        </div>

        <Separator />

        <div class="flex gap-3">
          <button
            type="button"
            class="flex-1 h-9 px-4 py-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground shadow-sm rounded-md text-sm font-medium transition-colors inline-flex items-center justify-center gap-2 cursor-pointer disabled:pointer-events-none disabled:opacity-50"
            onclick={goBack}
            onkeydown={(e) => (e.key === "Enter" || e.key === " ") && goBack}
            disabled={isSubmitting}
          >
            <ArrowLeft class="h-4 w-4 mr-2" />
            Back
          </button>
          <button
            type="button"
            class="flex-1 h-9 px-4 py-2 bg-primary text-primary-foreground hover:bg-primary/90 shadow rounded-md text-sm font-medium transition-colors inline-flex items-center justify-center gap-2 cursor-pointer disabled:pointer-events-none disabled:opacity-50"
            onclick={confirmAcceptance}
            onkeydown={(e) =>
              (e.key === "Enter" || e.key === " ") && confirmAcceptance}
            disabled={isSubmitting || !formIsValid}
          >
            <CheckCircle class="h-4 w-4 mr-2" />
            {isSubmitting ? "Creating Account..." : "Join Project"}
          </button>
        </div>
      </CardContent>
    </Card>
  </div>
</div>
