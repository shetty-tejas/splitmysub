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
  import { Input } from "$lib/components/ui/input";
  import { Textarea } from "$lib/components/ui/textarea";
  import {
    ArrowLeft,
    Check,
    X,
    AlertTriangle,
    FileText,
    Download,
    MessageSquare,
    Clock,
    User,
    DollarSign,
    Calendar,
    Eye,
  } from "lucide-svelte";

  export let project;
  export let payment;
  export let billing_cycle;

  let actionType = "";
  let actionNotes = "";
  let disputeReason = "";
  let newNote = "";
  let showActionModal = false;
  let showNoteModal = false;

  function formatCurrency(amount) {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
    }).format(amount);
  }

  function formatDate(dateString) {
    if (!dateString) return "Not set";
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  }

  function formatDateTime(dateString) {
    if (!dateString) return "Not set";
    return new Date(dateString).toLocaleString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  }

  function formatFileSize(bytes) {
    if (!bytes) return "";
    const k = 1024;
    const sizes = ["Bytes", "KB", "MB", "GB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i];
  }

  function getStatusColor(status) {
    switch (status) {
      case "confirmed":
        return "bg-green-100 text-green-800";
      case "rejected":
        return "bg-red-100 text-red-800";
      case "pending":
      default:
        return "bg-yellow-100 text-yellow-800";
    }
  }

  function getStatusIcon(status) {
    switch (status) {
      case "confirmed":
        return Check;
      case "rejected":
        return X;
      case "pending":
      default:
        return AlertTriangle;
    }
  }

  function getAmountStatus() {
    if (payment.exact_amount)
      return { text: "Exact Amount", color: "text-green-600" };
    if (payment.overpaid) return { text: "Overpaid", color: "text-blue-600" };
    if (payment.underpaid)
      return { text: "Underpaid", color: "text-orange-600" };
    return { text: "Unknown", color: "text-gray-600" };
  }

  function goBack() {
    router.get(`/projects/${project.slug}/payment_confirmations`);
  }

  function downloadEvidence() {
    window.open(`/payments/${payment.id}/download_evidence`, "_blank");
  }

  function openActionModal(action) {
    actionType = action;
    actionNotes = "";
    disputeReason = "";
    showActionModal = true;
  }

  function closeActionModal() {
    showActionModal = false;
    actionType = "";
    actionNotes = "";
    disputeReason = "";
  }

  function submitAction() {
    const formData = new FormData();
    formData.append("action_type", actionType);

    if (actionType === "dispute") {
      formData.append("dispute_reason", disputeReason);
    } else {
      formData.append("notes", actionNotes);
    }

    router.patch(
      `/projects/${project.slug}/payment_confirmations/${payment.id}`,
      formData,
      {
        onSuccess: () => {
          closeActionModal();
        },
      },
    );
  }

  function openNoteModal() {
    newNote = "";
    showNoteModal = true;
  }

  function closeNoteModal() {
    showNoteModal = false;
    newNote = "";
  }

  function submitNote() {
    const formData = new FormData();
    formData.append("note", newNote);

    router.post(
      `/projects/${project.slug}/payment_confirmations/${payment.id}/add_note`,
      formData,
      {
        onSuccess: () => {
          closeNoteModal();
        },
      },
    );
  }
</script>

<svelte:head>
  <title
    >Payment Review - {payment.user.email_address} - {project.name} - SplitSub</title
  >
</svelte:head>

<Layout>
  <div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
    <!-- Header -->
    <div class="flex items-center justify-between mb-8">
      <div class="flex items-center gap-4">
        <button
          type="button"
          onclick={goBack} onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && (goBack)}
          class="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-muted-foreground hover:text-foreground hover:bg-accent hover:bg-opacity-50 rounded-md transition-colors cursor-pointer"
        >
          <ArrowLeft class="h-4 w-4" />
          Back to Payment Confirmations
        </button>
      </div>
    </div>

    <!-- Payment Header -->
    <div class="mb-8">
      <div class="flex items-start justify-between mb-4">
        <div class="flex-1">
          <h1 class="text-3xl font-bold tracking-tight mb-2">Payment Review</h1>
          <p class="text-muted-foreground text-lg">
            Payment from <strong>{payment.user.email_address}</strong> for
            <strong>{project.name}</strong>
          </p>
        </div>
        <div class="flex flex-col gap-2">
          <Badge class={getStatusColor(payment.status)}>
            <svelte:component
              this={getStatusIcon(payment.status)}
              class="h-4 w-4 mr-2"
            />
            {payment.status.charAt(0).toUpperCase() + payment.status.slice(1)}
          </Badge>
          {#if payment.disputed}
            <Badge class="bg-orange-100 text-orange-800">
              <AlertTriangle class="h-4 w-4 mr-2" />
              Disputed
            </Badge>
          {/if}
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      <!-- Main Content -->
      <div class="lg:col-span-2 space-y-6">
        <!-- Payment Information -->
        <Card>
          <CardHeader>
            <CardTitle class="flex items-center gap-2">
              <DollarSign class="h-5 w-5" />
              Payment Information
            </CardTitle>
          </CardHeader>
          <CardContent class="space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <span class="text-muted-foreground text-sm">Amount Paid</span>
                <p class="text-2xl font-bold text-green-600">
                  {formatCurrency(payment.amount)}
                </p>
              </div>
              <div>
                <span class="text-muted-foreground text-sm"
                  >Expected Amount</span
                >
                <p class="text-lg font-medium">
                  {formatCurrency(payment.expected_amount)}
                </p>
              </div>
              <div>
                <span class="text-muted-foreground text-sm">Amount Status</span>
                <p class="font-medium {getAmountStatus().color}">
                  {getAmountStatus().text}
                </p>
              </div>
              <div>
                <span class="text-muted-foreground text-sm">Submitted</span>
                <p class="font-medium">{formatDateTime(payment.created_at)}</p>
              </div>
              {#if payment.confirmation_date}
                <div>
                  <span class="text-muted-foreground text-sm">Confirmed</span>
                  <p class="font-medium">
                    {formatDate(payment.confirmation_date)}
                  </p>
                </div>
              {/if}
              {#if payment.transaction_id}
                <div>
                  <span class="text-muted-foreground text-sm"
                    >Transaction ID</span
                  >
                  <p class="font-medium font-mono text-sm">
                    {payment.transaction_id}
                  </p>
                </div>
              {/if}
            </div>

            {#if payment.notes}
              <div>
                <span class="text-muted-foreground text-sm">Member Notes</span>
                <p class="mt-1 p-3 bg-muted rounded-md text-sm">
                  {payment.notes}
                </p>
              </div>
            {/if}
          </CardContent>
        </Card>

        <!-- Billing Cycle Information -->
        <Card>
          <CardHeader>
            <CardTitle class="flex items-center gap-2">
              <Calendar class="h-5 w-5" />
              Billing Cycle
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <span class="text-muted-foreground text-sm">Due Date</span>
                <p class="font-medium">{formatDate(billing_cycle.due_date)}</p>
              </div>
              <div>
                <span class="text-muted-foreground text-sm">Total Amount</span>
                <p class="font-medium">
                  {formatCurrency(billing_cycle.total_amount)}
                </p>
              </div>
              <div>
                <span class="text-muted-foreground text-sm"
                  >Amount Remaining</span
                >
                <p class="font-medium">
                  {formatCurrency(billing_cycle.amount_remaining)}
                </p>
              </div>
            </div>
            {#if billing_cycle.fully_paid}
              <div
                class="mt-4 p-3 bg-green-50 border border-green-200 rounded-md"
              >
                <p class="text-green-800 font-medium">
                  ✅ This billing cycle is fully paid!
                </p>
              </div>
            {/if}
          </CardContent>
        </Card>

        <!-- Status History -->
        {#if payment.status_history && payment.status_history.length > 0}
          <Card>
            <CardHeader>
              <CardTitle class="flex items-center gap-2">
                <Clock class="h-5 w-5" />
                Status History
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div class="space-y-3">
                {#each payment.status_history as change}
                  <div class="flex items-center gap-3 p-3 bg-muted rounded-md">
                    <div class="flex-1">
                      <p class="text-sm">
                        Status changed from <strong
                          >{change.from_status || "new"}</strong
                        >
                        to
                        <strong>{change.to_status}</strong>
                      </p>
                      <p class="text-xs text-muted-foreground">
                        {formatDateTime(change.changed_at)}
                        {#if change.changed_by}
                          by {change.changed_by}
                        {/if}
                      </p>
                    </div>
                  </div>
                {/each}
              </div>
            </CardContent>
          </Card>
        {/if}

        <!-- Dispute Information -->
        {#if payment.disputed}
          <Card class="border-orange-200">
            <CardHeader>
              <CardTitle class="flex items-center gap-2 text-orange-800">
                <AlertTriangle class="h-5 w-5" />
                Dispute Information
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div class="space-y-3">
                <div>
                  <span class="text-muted-foreground text-sm"
                    >Dispute Reason</span
                  >
                  <p
                    class="mt-1 p-3 bg-orange-50 border border-orange-200 rounded-md text-sm"
                  >
                    {payment.dispute_reason}
                  </p>
                </div>
                {#if payment.dispute_resolved_at}
                  <div>
                    <span class="text-muted-foreground text-sm">Resolved</span>
                    <p class="font-medium">
                      {formatDateTime(payment.dispute_resolved_at)}
                    </p>
                  </div>
                {/if}
              </div>
            </CardContent>
          </Card>
        {/if}
      </div>

      <!-- Sidebar -->
      <div class="space-y-6">
        <!-- Evidence -->
        <Card>
          <CardHeader>
            <CardTitle class="flex items-center gap-2">
              <FileText class="h-5 w-5" />
              Payment Evidence
            </CardTitle>
          </CardHeader>
          <CardContent>
            {#if payment.has_evidence}
              <div class="space-y-4">
                <div class="p-4 border rounded-lg">
                  <div class="flex items-center gap-3 mb-3">
                    <div class="flex-shrink-0">
                      {#if payment.evidence_content_type?.startsWith("image/")}
                        🖼️
                      {:else if payment.evidence_content_type === "application/pdf"}
                        📄
                      {:else}
                        📎
                      {/if}
                    </div>
                    <div class="flex-1 min-w-0">
                      <p class="font-medium text-sm truncate">
                        {payment.evidence_filename}
                      </p>
                      <p class="text-xs text-muted-foreground">
                        {formatFileSize(payment.evidence_byte_size)}
                      </p>
                    </div>
                  </div>

                  {#if payment.evidence_content_type?.startsWith("image/")}
                    <div class="mb-3">
                      <img
                        src={payment.evidence_url}
                        alt="Payment evidence"
                        class="w-full h-48 object-cover rounded-md border"
                      />
                    </div>
                  {/if}

                  <Button
                    onclick={downloadEvidence} onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && (downloadEvidence)}
                    variant="outline"
                    size="sm"
                    class="w-full"
                  >
                    <Download class="h-4 w-4 mr-2" />
                    Download Evidence
                  </Button>
                </div>
              </div>
            {:else}
              <div class="text-center py-6">
                <FileText
                  class="h-12 w-12 mx-auto mb-3 text-muted-foreground"
                />
                <p class="text-muted-foreground">No file evidence uploaded</p>
                {#if payment.transaction_id}
                  <p class="text-sm text-muted-foreground mt-1">
                    Transaction ID provided instead
                  </p>
                {/if}
              </div>
            {/if}
          </CardContent>
        </Card>

        <!-- Actions -->
        <Card>
          <CardHeader>
            <CardTitle>Actions</CardTitle>
          </CardHeader>
          <CardContent class="space-y-3">
            {#if payment.status === "pending"}
              <Button
                onclick={() => openActionModal("confirm")} onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && (() => openActionModal("confirm"))}
                class="w-full bg-green-600 hover:bg-green-700"
              >
                <Check class="h-4 w-4 mr-2" />
                Confirm Payment
              </Button>
              <Button
                onclick={() => openActionModal("reject")} onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && (() => openActionModal("reject"))}
                variant="destructive"
                class="w-full"
              >
                <X class="h-4 w-4 mr-2" />
                Reject Payment
              </Button>
            {/if}

            {#if !payment.disputed}
              <Button
                onclick={() => openActionModal("dispute")} onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && (() => openActionModal("dispute"))}
                variant="outline"
                class="w-full"
              >
                <AlertTriangle class="h-4 w-4 mr-2" />
                Mark as Disputed
              </Button>
            {:else}
              <Button
                onclick={() => openActionModal("resolve_dispute")} onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && (() => openActionModal("resolve_dispute"))}
                variant="outline"
                class="w-full"
              >
                <Check class="h-4 w-4 mr-2" />
                Resolve Dispute
              </Button>
            {/if}

            <Button onclick={openNoteModal} onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && (openNoteModal)} variant="outline" class="w-full">
              <MessageSquare class="h-4 w-4 mr-2" />
              Add Note
            </Button>
          </CardContent>
        </Card>

        <!-- Confirmation Notes -->
        {#if payment.confirmation_notes}
          <Card>
            <CardHeader>
              <CardTitle class="flex items-center gap-2">
                <MessageSquare class="h-5 w-5" />
                Confirmation Notes
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div class="p-3 bg-muted rounded-md text-sm whitespace-pre-wrap">
                {payment.confirmation_notes}
              </div>
            </CardContent>
          </Card>
        {/if}

        <!-- Confirmed By -->
        {#if payment.confirmed_by}
          <Card>
            <CardHeader>
              <CardTitle class="flex items-center gap-2">
                <User class="h-5 w-5" />
                Confirmed By
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p class="font-medium">{payment.confirmed_by.email_address}</p>
              {#if payment.confirmation_date}
                <p class="text-sm text-muted-foreground">
                  {formatDateTime(payment.confirmation_date)}
                </p>
              {/if}
            </CardContent>
          </Card>
        {/if}
      </div>
    </div>
  </div>

  <!-- Action Modal -->
  {#if showActionModal}
    <div
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
      onclick={closeActionModal}
      onkeydown={(e) => e.key === "Escape" && closeActionModal()}
      role="dialog"
      aria-modal="true"
      aria-labelledby="action-modal-title"
      tabindex="-1"
    >
      <div
        class="bg-white rounded-lg p-6 w-full max-w-md mx-4"
        onclick={(e) = role="button" tabindex="0"> { e.stopPropagation(); }}
        onkeydown={() => {}}
        role="document"
      >
        <h3 id="action-modal-title" class="text-lg font-semibold mb-4">
          {#if actionType === "confirm"}
            Confirm Payment
          {:else if actionType === "reject"}
            Reject Payment
          {:else if actionType === "dispute"}
            Mark as Disputed
          {:else if actionType === "resolve_dispute"}
            Resolve Dispute
          {/if}
        </h3>

        <div class="space-y-4">
          {#if actionType === "dispute"}
            <div>
              <label
                for="dispute-reason-textarea"
                class="block text-sm font-medium mb-2">Dispute Reason</label
              >
              <Textarea
                id="dispute-reason-textarea"
                bind:value={disputeReason}
                placeholder="Explain why this payment is being disputed..."
                rows="3"
                required
              />
            </div>
          {:else if actionType !== "resolve_dispute"}
            <div>
              <label
                for="action-notes-textarea"
                class="block text-sm font-medium mb-2">Notes (Optional)</label
              >
              <Textarea
                id="action-notes-textarea"
                bind:value={actionNotes}
                placeholder="Add any notes about this action..."
                rows="3"
              />
            </div>
          {/if}
        </div>

        <div class="flex justify-end gap-2 mt-6">
          <Button onclick={closeActionModal} onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && (closeActionModal)} variant="outline">Cancel</Button>
          <Button
            onclick={submitAction} onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && (submitAction)}
            disabled={actionType === "dispute" && !disputeReason.trim()}
          >
            {#if actionType === "confirm"}
              Confirm
            {:else if actionType === "reject"}
              Reject
            {:else if actionType === "dispute"}
              Mark as Disputed
            {:else if actionType === "resolve_dispute"}
              Resolve Dispute
            {/if}
          </Button>
        </div>
      </div>
    </div>
  {/if}

  <!-- Note Modal -->
  {#if showNoteModal}
    <div
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
      onclick={closeNoteModal}
      onkeydown={(e) => e.key === "Escape" && closeNoteModal()}
      role="dialog"
      aria-modal="true"
      aria-labelledby="note-modal-title"
      tabindex="-1"
    >
      <div
        class="bg-white rounded-lg p-6 w-full max-w-md mx-4"
        onclick={(e) = role="button" tabindex="0"> { e.stopPropagation(); }}
        onkeydown={() => {}}
        role="document"
      >
        <h3 id="note-modal-title" class="text-lg font-semibold mb-4">
          Add Note
        </h3>

        <div class="space-y-4">
          <div>
            <label
              for="new-note-textarea"
              class="block text-sm font-medium mb-2">Note</label
            >
            <Textarea
              id="new-note-textarea"
              bind:value={newNote}
              placeholder="Add a note about this payment..."
              rows="4"
              required
            />
          </div>
        </div>

        <div class="flex justify-end gap-2 mt-6">
          <Button onclick={closeNoteModal} onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && (closeNoteModal)} variant="outline">Cancel</Button>
          <Button onclick={submitNote} onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && (submitNote)} disabled={!newNote.trim()}>
            Add Note
          </Button>
        </div>
      </div>
    </div>
  {/if}
</Layout>
