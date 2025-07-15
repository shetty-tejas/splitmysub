<script>
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
    Mail,
    CheckCircle,
    Clock,
    DollarSign,
    AlertTriangle,
  } from "@lucide/svelte";
  import {
    formatCurrency,
    formatDate,
    getBillingCycleBadgeVariant,
  } from "$lib/billing-utils";

  export let invitation;
  export let project;
  export let user_email;
</script>

<svelte:head>
  <title>Check Your Email - {project.name} - SplitMySub</title>
</svelte:head>

<div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
  <!-- Header -->
  <div class="text-center mb-8">
    <div class="mb-4">
      <div class="text-2xl font-bold text-blue-600 mb-2">SplitMySub</div>
      <p class="text-muted-foreground">Subscription Cost Sharing Made Simple</p>
    </div>

    <div class="flex justify-center mb-4">
      <div class="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center">
        <Mail class="h-8 w-8 text-blue-600" />
      </div>
    </div>

    <h1 class="text-3xl font-bold tracking-tight mb-2">Check Your Email</h1>
    <p class="text-lg text-muted-foreground max-w-2xl mx-auto">
      We've sent a verification link to <strong>{user_email}</strong> to complete your account setup and join {project.name}.
    </p>
  </div>

  <div class="grid gap-6 lg:grid-cols-2 max-w-4xl mx-auto">
    <!-- Email Verification Instructions -->
    <Card>
      <CardHeader>
        <CardTitle class="flex items-center gap-2">
          <CheckCircle class="h-5 w-5 text-green-600" />
          Next Steps
        </CardTitle>
        <CardDescription>
          Complete your account verification to join the project
        </CardDescription>
      </CardHeader>
      <CardContent class="space-y-4">
        <div class="space-y-3">
          <div class="flex items-start gap-3">
            <div class="w-6 h-6 bg-blue-100 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5">
              <span class="text-xs font-medium text-blue-600">1</span>
            </div>
            <div>
              <p class="font-medium">Check your email</p>
              <p class="text-sm text-muted-foreground">
                Look for an email from SplitMySub in your inbox
              </p>
            </div>
          </div>

          <div class="flex items-start gap-3">
            <div class="w-6 h-6 bg-blue-100 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5">
              <span class="text-xs font-medium text-blue-600">2</span>
            </div>
            <div>
              <p class="font-medium">Click the verification link</p>
              <p class="text-sm text-muted-foreground">
                The link will verify your email and complete your account setup
              </p>
            </div>
          </div>

          <div class="flex items-start gap-3">
            <div class="w-6 h-6 bg-blue-100 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5">
              <span class="text-xs font-medium text-blue-600">3</span>
            </div>
            <div>
              <p class="font-medium">Join the project</p>
              <p class="text-sm text-muted-foreground">
                You'll be automatically added to {project.name} and can start participating
              </p>
            </div>
          </div>
        </div>

        <Separator />

        <div class="bg-amber-50 border border-amber-200 rounded-lg p-4">
          <div class="flex items-center gap-2 text-amber-800">
            <Clock class="h-4 w-4" />
            <span class="font-medium">Verification Link Expires</span>
          </div>
          <p class="text-sm text-amber-700 mt-1">
            The verification link will expire in 30 minutes. If you don't see the email, check your spam folder.
          </p>
        </div>
      </CardContent>
    </Card>

    <!-- Project Preview -->
    <Card>
      <CardHeader>
        <CardTitle class="flex items-center gap-2">
          <DollarSign class="h-5 w-5" />
          Project Preview
        </CardTitle>
        <CardDescription>
          What you'll be joining once verified
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
            <span class="text-lg font-semibold">
              {formatCurrency(project.cost)}
            </span>
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
        </div>
      </CardContent>
    </Card>
  </div>

  <!-- Troubleshooting -->
  <Card class="max-w-4xl mx-auto mt-6">
    <CardHeader>
      <CardTitle class="flex items-center gap-2">
        <AlertTriangle class="h-5 w-5" />
        Didn't receive the email?
      </CardTitle>
    </CardHeader>
    <CardContent>
      <div class="grid md:grid-cols-2 gap-4 text-sm">
        <div class="space-y-2">
          <p class="font-medium">Check these common issues:</p>
          <ul class="text-muted-foreground space-y-1">
            <li>• Look in your spam or junk folder</li>
            <li>• Make sure you entered the correct email address</li>
            <li>• The verification link expires in 30 minutes</li>
            <li>• Check if your email provider blocks our emails</li>
          </ul>
        </div>
        <div class="space-y-2">
          <p class="font-medium">Still having trouble?</p>
          <ul class="text-muted-foreground space-y-1">
            <li>• Wait a few minutes and check again</li>
            <li>• Try signing up again with the same email</li>
            <li>• Contact the project owner for help</li>
            <li>• Reach out to our support team</li>
          </ul>
        </div>
      </div>
    </CardContent>
  </Card>
</div>