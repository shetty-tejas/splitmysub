<script>
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
  import {
    ArrowLeft,
    Mail,
    Clock,
    CheckCircle,
    XCircle,
    Trash2,
    UserPlus,
  } from "lucide-svelte";
  import InviteForm from "../../components/invitations/InviteForm.svelte";

  export let project;
  export let invitations;

  function formatDateTime(dateString) {
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  }

  function getStatusBadgeVariant(status) {
    switch (status) {
      case "pending":
        return "default";
      case "accepted":
        return "success";
      case "declined":
        return "destructive";
      case "expired":
        return "secondary";
      default:
        return "default";
    }
  }

  function getStatusIcon(status) {
    switch (status) {
      case "pending":
        return Clock;
      case "accepted":
        return CheckCircle;
      case "declined":
      case "expired":
        return XCircle;
      default:
        return Clock;
    }
  }

  function goBack() {
    router.get(`/projects/${project.slug}`);
  }

  function deleteInvitation(invitationId) {
    if (confirm("Are you sure you want to cancel this invitation?")) {
      router.delete(`/projects/${project.slug}/invitations/${invitationId}`);
    }
  }

  function copyInvitationLink(token) {
    const url = `${window.location.origin}/invitations/${token}`;
    navigator.clipboard.writeText(url).then(() => {
      // You could show a toast notification here
      alert("Invitation link copied to clipboard!");
    });
  }
</script>

<svelte:head>
  <title>Invitations - {project.name} - SplitMySub</title>
</svelte:head>

<Layout>
  <div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
    <!-- Header -->
    <div class="flex items-center justify-between mb-8">
      <div class="flex items-center gap-4">
        <button
          type="button"
          onclick={goBack}
          onkeydown={(e) => (e.key === "Enter" || e.key === " ") && goBack}
          class="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-muted-foreground hover:text-foreground hover:bg-accent hover:bg-opacity-50 rounded-md transition-colors cursor-pointer"
        >
          <ArrowLeft class="h-4 w-4" />
          Back to Project
        </button>
      </div>
    </div>

    <!-- Project Header -->
    <div class="mb-8">
      <h1 class="text-3xl font-bold tracking-tight mb-2">Invitations</h1>
      <p class="text-muted-foreground text-lg">
        Manage invitations and track who has access to <strong
          >{project.name}</strong
        >
      </p>
    </div>

    <!-- Action Buttons -->
    <div class="flex flex-col sm:flex-row gap-2 mb-8">
      <InviteForm {project} />
    </div>

    <!-- Invitations List -->
    <Card>
      <CardHeader>
        <CardTitle class="flex items-center gap-2">
          <Mail class="h-5 w-5" />
          Sent Invitations ({invitations.length})
        </CardTitle>
        <CardDescription>
          Track the status of all invitations sent for this project
        </CardDescription>
      </CardHeader>
      <CardContent>
        {#if invitations.length > 0}
          <div class="space-y-4">
            {#each invitations as invitation}
              <div
                class="flex items-center justify-between p-4 border rounded-lg"
              >
                <div class="flex-1">
                  <div class="flex items-center gap-3 mb-2">
                    <div class="flex items-center gap-2">
                      <svelte:component
                        this={getStatusIcon(invitation.status)}
                        class="h-4 w-4"
                      />
                      <span class="font-medium">{invitation.email}</span>
                    </div>
                    <Badge variant={getStatusBadgeVariant(invitation.status)}>
                      {invitation.status}
                    </Badge>
                    <Badge variant="outline">{invitation.role}</Badge>
                  </div>

                  <div class="text-sm text-muted-foreground space-y-1">
                    <p>
                      Invited by {invitation.invited_by.name} on {formatDateTime(
                        invitation.created_at,
                      )}
                    </p>
                    {#if invitation.status === "pending"}
                      <p>
                        Expires on {formatDateTime(invitation.expires_at)}
                      </p>
                    {/if}
                  </div>
                </div>

                <div class="flex items-center gap-2">
                  {#if invitation.status === "pending"}
                    <Button
                      variant="outline"
                      size="sm"
                      onclick={() => copyInvitationLink(invitation.token)}
                      onkeydown={(e) =>
                        (e.key === "Enter" || e.key === " ") &&
                        (() => copyInvitationLink(invitation.token))}
                    >
                      Copy Link
                    </Button>
                    <Button
                      variant="destructive"
                      size="sm"
                      onclick={() => deleteInvitation(invitation.id)}
                      onkeydown={(e) =>
                        (e.key === "Enter" || e.key === " ") &&
                        (() => deleteInvitation(invitation.id))}
                    >
                      <Trash2 class="h-4 w-4" />
                    </Button>
                  {/if}
                </div>
              </div>
            {/each}
          </div>
        {:else}
          <div class="text-center py-8 text-muted-foreground">
            <UserPlus class="h-12 w-12 mx-auto mb-4 opacity-50" />
            <h3 class="text-lg font-medium mb-2">No invitations sent yet</h3>
            <p class="mb-4">Start by inviting members to join this project</p>
            <InviteForm {project} />
          </div>
        {/if}
      </CardContent>
    </Card>
  </div>
</Layout>
