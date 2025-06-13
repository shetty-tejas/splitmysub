<script>
  import { router } from "@inertiajs/svelte";
  import { Button } from "$lib/components/ui/button";
  import { Input } from "$lib/components/ui/input";
  import { Label } from "$lib/components/ui/label";
  import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
    DialogClose,
  } from "$lib/components/ui/dialog";
  import { UserPlus, Mail } from "lucide-svelte";

  export let project;

  let email = "";
  let role = "member";
  let isSubmitting = false;
  let emailError = "";

  function validateEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  function handleSubmit() {
    emailError = "";

    if (!email.trim()) {
      emailError = "Email is required";
      return;
    }

    if (!validateEmail(email.trim())) {
      emailError = "Please enter a valid email address";
      return;
    }

    isSubmitting = true;

    router.post(
      `/projects/${project.id}/invitations`,
      {
        invitation: {
          email: email.trim(),
          role: role,
        },
      },
      {
        onSuccess: () => {
          email = "";
          role = "member";
          isSubmitting = false;
          // The dialog will close automatically on success
        },
        onError: () => {
          isSubmitting = false;
        },
      },
    );
  }

  function handleKeydown(event) {
    if (event.key === "Enter") {
      event.preventDefault();
      handleSubmit();
    }
  }

  function resetForm() {
    email = "";
    role = "member";
    isSubmitting = false;
    emailError = "";
  }

  function handleEmailInput() {
    if (emailError && email.trim()) {
      emailError = "";
    }
  }
</script>

<Dialog onOpenChange={resetForm}>
  <DialogTrigger>
    <Button variant="outline" size="sm">
      <UserPlus class="h-4 w-4 mr-2" />
      Invite Member
    </Button>
  </DialogTrigger>
  <DialogContent class="sm:max-w-md">
    <DialogHeader>
      <DialogTitle class="flex items-center gap-2">
        <Mail class="h-5 w-5" />
        Invite Member to {project.name}
      </DialogTitle>
      <DialogDescription>
        Send an invitation to join this subscription project. They'll receive an
        email with instructions.
      </DialogDescription>
    </DialogHeader>

    <form on:submit|preventDefault={handleSubmit} class="space-y-4">
      <div class="space-y-2">
        <Label for="email">Email Address</Label>
        <Input
          id="email"
          type="email"
          placeholder="Enter email address"
          bind:value={email}
          on:keydown={handleKeydown}
          on:input={handleEmailInput}
          required
          disabled={isSubmitting}
          class={emailError ? "border-red-500" : ""}
        />
        {#if emailError}
          <p class="text-sm text-red-600 mt-1">{emailError}</p>
        {/if}
      </div>

      <div class="space-y-2">
        <Label for="role">Role</Label>
        <select
          id="role"
          bind:value={role}
          disabled={isSubmitting}
          class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
        >
          <option value="member">Member</option>
          <option value="admin">Admin</option>
        </select>
        <p class="text-xs text-muted-foreground">
          Admins can invite other members and manage the project.
        </p>
      </div>

      <div class="flex justify-end gap-2 pt-4">
        <DialogClose>
          <Button type="button" variant="outline" disabled={isSubmitting}>
            Cancel
          </Button>
        </DialogClose>
        <Button type="submit" disabled={!email.trim() || isSubmitting}>
          {#if isSubmitting}
            Sending...
          {:else}
            Send Invitation
          {/if}
        </Button>
      </div>
    </form>
  </DialogContent>
</Dialog>
