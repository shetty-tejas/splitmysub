<script>
  import { router } from "@inertiajs/svelte";
  import { editProfilePath } from "../../routes/index.js";
  import Layout from "../../layouts/layout.svelte";
  import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
  } from "$lib/components/ui/card";
  import { Button } from "$lib/components/ui/button";
  import { Separator } from "$lib/components/ui/separator";
  import { Edit, User, Mail, Calendar } from "lucide-svelte";

  export let user;

  function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  }

  function editProfile() {
    router.get(editProfilePath());
  }
</script>

<svelte:head>
  <title>Profile - SplitSub</title>
</svelte:head>

<Layout>
  <div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
    <div class="mx-auto max-w-2xl">
      <Card>
        <CardHeader>
          <CardTitle class="flex items-center gap-2 text-2xl">
            <User class="h-6 w-6" />
            Personal Information
          </CardTitle>
          <CardDescription>
            Your account details and personal information
          </CardDescription>
        </CardHeader>
        <CardContent class="space-y-6">
          <!-- Personal Details -->
          <div class="space-y-4">
            <h3 class="text-lg font-semibold">Personal Details</h3>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div class="space-y-2">
                <dt class="text-sm font-medium text-muted-foreground">
                  First Name
                </dt>
                <dd class="text-sm font-medium">{user.first_name}</dd>
              </div>

              <div class="space-y-2">
                <dt class="text-sm font-medium text-muted-foreground">
                  Last Name
                </dt>
                <dd class="text-sm font-medium">{user.last_name}</dd>
              </div>
            </div>

            <div class="space-y-2">
              <dt class="text-sm font-medium text-muted-foreground">
                Full Name
              </dt>
              <dd class="text-sm font-medium">
                {user.first_name}
                {user.last_name}
              </dd>
            </div>
          </div>

          <Separator />

          <!-- Account Information -->
          <div class="space-y-4">
            <h3 class="text-lg font-semibold">Account Information</h3>

            <div class="space-y-2">
              <dt
                class="text-sm font-medium text-muted-foreground flex items-center gap-2"
              >
                <Mail class="h-4 w-4" />
                Email Address
              </dt>
              <dd class="text-sm font-medium">{user.email_address}</dd>
            </div>

            <div class="space-y-2">
              <dt
                class="text-sm font-medium text-muted-foreground flex items-center gap-2"
              >
                <Calendar class="h-4 w-4" />
                Member Since
              </dt>
              <dd class="text-sm font-medium">{formatDate(user.created_at)}</dd>
            </div>
          </div>

          <!-- Actions -->
          <div class="pt-6">
            <Button on:click={editProfile} class="w-full sm:w-auto">
              <Edit class="h-4 w-4 mr-2" />
              Edit Profile
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  </div>
</Layout>
