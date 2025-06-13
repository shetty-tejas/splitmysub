<script>
  import { router } from "@inertiajs/svelte";
  import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
  } from "$lib/components/ui/card";
  import { CheckCircle, Home } from "lucide-svelte";

  export let invitation;
  export let project;

  function goHome() {
    router.get("/");
  }
</script>

<svelte:head>
  <title>Invitation Declined - SplitSub</title>
</svelte:head>

<div
  class="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 flex items-center justify-center p-4"
>
  <div class="w-full max-w-md">
    <Card class="shadow-lg">
      <CardHeader class="text-center pb-4">
        <div
          class="mx-auto w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mb-4"
        >
          <CheckCircle class="h-8 w-8 text-green-600" />
        </div>
        <CardTitle class="text-2xl font-bold text-gray-900">
          Thank You
        </CardTitle>
        <CardDescription class="text-gray-600">
          Your response has been recorded
        </CardDescription>
      </CardHeader>

      <CardContent class="space-y-6">
        <!-- Project Information -->
        <div class="bg-gray-50 rounded-lg p-4">
          <h3 class="font-semibold text-gray-900 mb-2">Invitation Details</h3>
          <div class="space-y-2 text-sm">
            <div>
              <span class="text-gray-600">Project:</span>
              <span class="font-medium ml-2">{project.name}</span>
            </div>
            <div>
              <span class="text-gray-600">Invited by:</span>
              <span class="font-medium ml-2">{invitation.invited_by.name}</span>
            </div>
            <div>
              <span class="text-gray-600">Status:</span>
              <span class="font-medium ml-2 text-red-600">Declined</span>
            </div>
          </div>
        </div>

        <!-- Thank you message -->
        <div class="text-center space-y-4">
          <div class="text-sm text-gray-600">
            <p>
              You have declined the invitation to join <strong
                >{project.name}</strong
              >.
            </p>
            <p class="mt-2">
              If you change your mind later, please contact {invitation
                .invited_by.name} for a new invitation.
            </p>
          </div>

          <div class="pt-4">
            <button
              type="button"
              on:click={goHome}
              class="inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 bg-primary text-primary-foreground hover:bg-primary/90 shadow h-9 px-4 py-2 w-full cursor-pointer"
            >
              <Home class="h-4 w-4" />
              Go to Homepage
            </button>
          </div>
        </div>
      </CardContent>
    </Card>
  </div>
</div>
