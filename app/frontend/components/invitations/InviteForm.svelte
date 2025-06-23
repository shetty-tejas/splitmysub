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
  import { UserPlus, Mail, Copy, Check } from "lucide-svelte";

  export let project;

  let email = "";
  let isSubmitting = false;
  let emailError = "";
  let inviteUrl = "";
  let copySuccess = false;
  let isGeneratingUrl = false;
  let invitationId = null;

  function validateEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  async function generateInviteUrl() {
    if (isGeneratingUrl) return;

    isGeneratingUrl = true;

    try {
      const response = await fetch(`/projects/${project.slug}/invitations`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token":
            document
              .querySelector('meta[name="csrf-token"]')
              ?.getAttribute("content") || "",
        },
        body: JSON.stringify({
          invitation: {
            email: email.trim() || null, // Allow null email for link-only invitations
            role: "member",
          },
        }),
      });

      if (response.ok) {
        const data = await response.json();
        if (data.invitation && data.invitation.token) {
          inviteUrl = `${window.location.origin}/invitations/${data.invitation.token}`;
          invitationId = data.invitation.id;
        }
      } else {
        console.error("Failed to generate invite URL:", response.statusText);
      }
    } catch (error) {
      console.error("Failed to generate invite URL:", error);
    } finally {
      isGeneratingUrl = false;
    }
  }

  async function handleSubmit() {
    emailError = "";

    if (email.trim() && !validateEmail(email.trim())) {
      emailError = "Please enter a valid email address";
      return;
    }

    // If we don't have an invite URL yet, generate one
    if (!inviteUrl) {
      generateInviteUrl();
      return;
    }

    // If we have both email and URL, send the invitation email
    if (email.trim() && inviteUrl && invitationId) {
      await sendInvitationEmail();
    }
  }

  async function sendInvitationEmail() {
    if (isSubmitting) return;

    isSubmitting = true;

    try {
      // First, update the invitation with the email address
      const updateResponse = await fetch(
        `/projects/${project.slug}/invitations/${invitationId}`,
        {
          method: "PATCH",
          headers: {
            "Content-Type": "application/json",
            Accept: "application/json",
            "X-CSRF-Token":
              document
                .querySelector('meta[name="csrf-token"]')
                ?.getAttribute("content") || "",
          },
          body: JSON.stringify({
            invitation: {
              email: email.trim(),
            },
          }),
        },
      );

      if (updateResponse.ok) {
        // Now send the email
        const emailResponse = await fetch(
          `/projects/${project.slug}/invitations/${invitationId}/send_email`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Accept: "application/json",
              "X-CSRF-Token":
                document
                  .querySelector('meta[name="csrf-token"]')
                  ?.getAttribute("content") || "",
            },
          },
        );

        if (emailResponse.ok) {
          const data = await emailResponse.json();
          // Show success message and clear email
          email = "";
          emailError = "";
          // You could show a success toast here
          console.log("Email sent successfully:", data.message);
        } else {
          const errorData = await emailResponse.json();
          emailError = errorData.error || "Failed to send email";
        }
      } else {
        emailError = "Failed to update invitation with email address";
      }
    } catch (error) {
      console.error("Failed to send invitation email:", error);
      emailError = "Failed to send email. Please try again.";
    } finally {
      isSubmitting = false;
    }
  }

  function handleKeydown(event) {
    if (event.key === "Enter") {
      event.preventDefault();
      handleSubmit();
    }
  }

  function resetForm() {
    email = "";
    isSubmitting = false;
    emailError = "";
    inviteUrl = "";
    copySuccess = false;
    isGeneratingUrl = false;
    invitationId = null;
  }

  function handleEmailInput() {
    if (emailError && email.trim()) {
      emailError = "";
    }
  }

  async function copyInviteUrl() {
    try {
      await navigator.clipboard.writeText(inviteUrl);
      copySuccess = true;
      setTimeout(() => {
        copySuccess = false;
      }, 2000);
    } catch (err) {
      console.error("Failed to copy: ", err);
    }
  }

  // Generate invite URL when modal opens
  function handleOpenChange(open) {
    if (open && !inviteUrl && !isGeneratingUrl) {
      generateInviteUrl();
    } else if (!open) {
      resetForm();
    }
  }
</script>

<Dialog onOpenChange={handleOpenChange}>
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
        Share this invitation link or enter an email address to send directly.
      </DialogDescription>
    </DialogHeader>

    <form onsubmit={(e) => { e.preventDefault(); handleSubmit(e); }} class="space-y-4">
      <div class="space-y-2">
        <Label for="email">Email Address (Optional)</Label>
        <Input
          id="email"
          type="email"
          placeholder="Enter email address to send invitation"
          bind:value={email}
          onkeydown={handleKeydown}
          oninput={handleEmailInput}
          disabled={isSubmitting || isGeneratingUrl}
          class={emailError ? "border-red-500" : ""}
        />
        {#if emailError}
          <p class="text-sm text-red-600 mt-1">{emailError}</p>
        {/if}
      </div>

      <div class="space-y-2">
        <Label for="invite-url">Invitation Link</Label>
        <div class="flex gap-2">
          <Input
            id="invite-url"
            type="text"
            value={inviteUrl}
            readonly
            placeholder={isGeneratingUrl
              ? "Generating invitation link..."
              : "Invitation link will appear here"}
            class="bg-muted"
          />
          <Button
            type="button"
            variant="outline"
            size="sm"
            onclick={copyInviteUrl}
            disabled={!inviteUrl || isGeneratingUrl}
            class="flex-shrink-0"
          >
            {#if copySuccess}
              <Check class="h-4 w-4" />
            {:else}
              <Copy class="h-4 w-4" />
            {/if}
          </Button>
        </div>
        {#if copySuccess}
          <p class="text-sm text-green-600">Link copied to clipboard!</p>
        {/if}
        <p class="text-xs text-muted-foreground">
          Share this link with anyone you want to invite to the project. They'll
          be added as members.
        </p>
      </div>

      <div class="flex justify-end gap-2 pt-4">
        <DialogClose>
          <Button
            type="button"
            variant="outline"
            disabled={isSubmitting || isGeneratingUrl}
          >
            Done
          </Button>
        </DialogClose>
        {#if email.trim() && inviteUrl}
          <Button type="submit" disabled={isSubmitting || isGeneratingUrl}>
            {#if isSubmitting}
              Sending...
            {:else}
              Send Email
            {/if}
          </Button>
        {/if}
      </div>
    </form>
  </DialogContent>
</Dialog>
