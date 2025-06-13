<script>
  import Layout from "../layouts/layout.svelte";
  import { buttonVariants } from "$lib/components/ui/button/button.svelte";
  import {
    Users,
    CreditCard,
    Bell,
    Shield,
    Calculator,
    Mail,
    ArrowRight,
    CheckCircle,
    DollarSign,
    Calendar,
  } from "lucide-svelte";
  import { Link } from "@inertiajs/svelte";
  import * as Card from "$lib/components/ui/card/index.js";

  const features = [
    {
      icon: Users,
      title: "Easy Sharing",
      description:
        "Invite friends and family to split subscription costs with simple email invitations.",
    },
    {
      icon: Calculator,
      title: "Smart Splitting",
      description:
        "Automatically calculate each person's share based on subscription costs and billing cycles.",
    },
    {
      icon: CreditCard,
      title: "Payment Tracking",
      description:
        "Track who has paid and upload receipts as proof of subscription costs.",
    },
    {
      icon: Bell,
      title: "Automated Reminders",
      description:
        "Never miss a payment with automated email reminders for upcoming bills.",
    },
    {
      icon: Shield,
      title: "Secure & Private",
      description:
        "Your financial information is protected with secure authentication and encryption.",
    },
    {
      icon: Mail,
      title: "Magic Link Login",
      description:
        "No passwords to remember - secure access with magic link authentication.",
    },
  ];

  const popularSubscriptions = [
    {
      name: "Netflix",
      cost: "$15.99",
      users: "4 people",
      savings: "$12/month",
    },
    {
      name: "Spotify Family",
      cost: "$16.99",
      users: "6 people",
      savings: "$42/month",
    },
    {
      name: "Disney+",
      cost: "$13.99",
      users: "3 people",
      savings: "$9.33/month",
    },
    {
      name: "YouTube Premium",
      cost: "$22.99",
      users: "5 people",
      savings: "$18.40/month",
    },
  ];
</script>

<svelte:head>
  <title>Splitsub - Split Subscription Costs with Friends</title>
  <meta
    name="description"
    content="Share and manage recurring subscriptions with friends and family. Split costs automatically and never miss a payment with Splitsub."
  />
</svelte:head>

<Layout>
  <!-- Hero Section -->
  <div class="bg-gradient-to-br from-blue-50 to-indigo-100 border-b">
    <div
      class="mx-auto max-w-2xl px-6 lg:max-w-7xl lg:px-8 border-l border-r border-dashed pt-20 pb-32"
    >
      <div class="text-center">
        <h1
          class="text-5xl font-bold tracking-tight text-gray-900 sm:text-6xl lg:text-7xl"
        >
          Split Subscriptions,
          <span class="text-blue-600">Save Money</span>
        </h1>
        <p class="mt-6 text-xl leading-8 text-gray-600 max-w-3xl mx-auto">
          Share Netflix, Spotify, and other subscriptions with friends and
          family. Automatically split costs, track payments, and never miss a
          bill again.
        </p>
        <div class="mt-10 flex items-center justify-center gap-x-6">
          <Link
            href="/signup"
            class={buttonVariants({ variant: "default", size: "lg" })}
          >
            <span>Get Started Free</span>
            <ArrowRight weight="bold" />
          </Link>
          <Link
            href="/login"
            class={buttonVariants({ variant: "outline", size: "lg" })}
          >
            <span>Sign In</span>
          </Link>
        </div>

        <!-- Stats -->
        <div class="mt-16 grid grid-cols-1 gap-8 sm:grid-cols-3">
          <div class="text-center">
            <div class="text-3xl font-bold text-blue-600">$200+</div>
            <div class="text-sm text-gray-600">Average yearly savings</div>
          </div>
          <div class="text-center">
            <div class="text-3xl font-bold text-blue-600">15+</div>
            <div class="text-sm text-gray-600">Popular services supported</div>
          </div>
          <div class="text-center">
            <div class="text-3xl font-bold text-blue-600">100%</div>
            <div class="text-sm text-gray-600">Free to use</div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- Popular Subscriptions Section -->
  <div class="py-24 bg-white">
    <div class="mx-auto max-w-2xl px-6 lg:max-w-7xl lg:px-8">
      <div class="text-center mb-16">
        <h2 class="text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">
          Popular Subscriptions to Split
        </h2>
        <p class="mt-4 text-lg text-gray-600">
          See how much you could save by sharing these popular services
        </p>
      </div>

      <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        {#each popularSubscriptions as sub}
          <Card.Root class="text-center">
            <Card.Header>
              <Card.Title class="text-lg">{sub.name}</Card.Title>
              <div class="text-2xl font-bold text-blue-600">{sub.cost}</div>
            </Card.Header>
            <Card.Content>
              <div class="space-y-2 text-sm text-gray-600">
                <div class="flex items-center justify-center gap-2">
                  <Users size={16} />
                  <span>{sub.users}</span>
                </div>
                <div
                  class="flex items-center justify-center gap-2 text-green-600 font-medium"
                >
                  <DollarSign size={16} />
                  <span>Save {sub.savings}</span>
                </div>
              </div>
            </Card.Content>
          </Card.Root>
        {/each}
      </div>
    </div>
  </div>

  <!-- Features Section -->
  <div id="features" class="py-24 bg-gray-50">
    <div class="mx-auto max-w-2xl px-6 lg:max-w-7xl lg:px-8">
      <div class="text-center mb-16">
        <h2 class="text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">
          Everything You Need to Split Subscriptions
        </h2>
        <p class="mt-4 text-lg text-gray-600">
          Powerful features that make sharing subscriptions simple and
          stress-free
        </p>
      </div>

      <div class="grid gap-8 md:grid-cols-2 lg:grid-cols-3">
        {#each features as feature}
          <Card.Root class="text-center">
            <Card.Header>
              <div
                class="mx-auto w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center mb-4"
              >
                <svelte:component
                  this={feature.icon}
                  size={24}
                  class="text-blue-600"
                />
              </div>
              <Card.Title class="text-xl">{feature.title}</Card.Title>
            </Card.Header>
            <Card.Content>
              <Card.Description class="text-base"
                >{feature.description}</Card.Description
              >
            </Card.Content>
          </Card.Root>
        {/each}
      </div>
    </div>
  </div>

  <!-- How It Works Section -->
  <div id="how-it-works" class="py-24 bg-white">
    <div class="mx-auto max-w-2xl px-6 lg:max-w-7xl lg:px-8">
      <div class="text-center mb-16">
        <h2 class="text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">
          How Splitsub Works
        </h2>
        <p class="mt-4 text-lg text-gray-600">
          Get started in minutes with our simple 4-step process
        </p>
      </div>

      <div class="grid gap-8 md:grid-cols-2 lg:grid-cols-4">
        <div class="text-center">
          <div
            class="mx-auto w-16 h-16 bg-blue-600 rounded-full flex items-center justify-center text-white font-bold text-xl mb-4"
          >
            1
          </div>
          <h3 class="text-lg font-semibold mb-2">Create Project</h3>
          <p class="text-gray-600">
            Set up a new subscription project with details like cost and billing
            cycle.
          </p>
        </div>
        <div class="text-center">
          <div
            class="mx-auto w-16 h-16 bg-blue-600 rounded-full flex items-center justify-center text-white font-bold text-xl mb-4"
          >
            2
          </div>
          <h3 class="text-lg font-semibold mb-2">Invite Friends</h3>
          <p class="text-gray-600">
            Send email invitations to friends and family you want to share with.
          </p>
        </div>
        <div class="text-center">
          <div
            class="mx-auto w-16 h-16 bg-blue-600 rounded-full flex items-center justify-center text-white font-bold text-xl mb-4"
          >
            3
          </div>
          <h3 class="text-lg font-semibold mb-2">Track Payments</h3>
          <p class="text-gray-600">
            Upload receipts and mark payments as complete when members pay their
            share.
          </p>
        </div>
        <div class="text-center">
          <div
            class="mx-auto w-16 h-16 bg-blue-600 rounded-full flex items-center justify-center text-white font-bold text-xl mb-4"
          >
            4
          </div>
          <h3 class="text-lg font-semibold mb-2">Get Reminders</h3>
          <p class="text-gray-600">
            Receive automated email reminders before payments are due.
          </p>
        </div>
      </div>
    </div>
  </div>

  <!-- Pricing Section -->
  <div id="pricing" class="py-24 bg-gray-50">
    <div class="mx-auto max-w-2xl px-6 lg:max-w-7xl lg:px-8">
      <div class="text-center mb-16">
        <h2 class="text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">
          Simple, Transparent Pricing
        </h2>
        <p class="mt-4 text-lg text-gray-600">
          Splitsub is completely free to use. No hidden fees, no subscriptions.
        </p>
      </div>

      <div class="max-w-lg mx-auto">
        <Card.Root class="text-center">
          <Card.Header>
            <Card.Title class="text-2xl">Free Forever</Card.Title>
            <div class="text-4xl font-bold text-blue-600">$0</div>
            <Card.Description>Perfect for everyone</Card.Description>
          </Card.Header>
          <Card.Content class="space-y-4">
            <div class="space-y-2 text-left">
              <div class="flex items-center gap-2">
                <CheckCircle size={20} class="text-green-600" />
                <span>Unlimited subscription projects</span>
              </div>
              <div class="flex items-center gap-2">
                <CheckCircle size={20} class="text-green-600" />
                <span>Unlimited group members</span>
              </div>
              <div class="flex items-center gap-2">
                <CheckCircle size={20} class="text-green-600" />
                <span>Payment tracking & reminders</span>
              </div>
              <div class="flex items-center gap-2">
                <CheckCircle size={20} class="text-green-600" />
                <span>Receipt uploads</span>
              </div>
              <div class="flex items-center gap-2">
                <CheckCircle size={20} class="text-green-600" />
                <span>Email notifications</span>
              </div>
              <div class="flex items-center gap-2">
                <CheckCircle size={20} class="text-green-600" />
                <span>Magic link authentication</span>
              </div>
            </div>
            <div class="pt-4">
              <Link
                href="/signup"
                class={buttonVariants({
                  variant: "default",
                  size: "lg",
                  class: "w-full",
                })}
              >
                <span>Get Started Free</span>
                <ArrowRight weight="bold" />
              </Link>
            </div>
          </Card.Content>
        </Card.Root>
      </div>
    </div>
  </div>

  <!-- CTA Section -->
  <div class="bg-blue-600">
    <div class="mx-auto max-w-2xl px-6 lg:max-w-7xl lg:px-8 py-16 text-center">
      <h2 class="text-3xl font-bold tracking-tight text-white sm:text-4xl">
        Ready to Start Saving?
      </h2>
      <p class="mt-4 text-xl text-blue-100">
        Join thousands of users who are already splitting subscriptions and
        saving money.
      </p>
      <div class="mt-8">
        <Link
          href="/signup"
          class={buttonVariants({ variant: "secondary", size: "lg" })}
        >
          <span>Get Started Free</span>
          <ArrowRight weight="bold" />
        </Link>
      </div>
      <p class="mt-4 text-sm text-blue-200">
        No credit card required • Free forever • Cancel anytime
      </p>
    </div>
  </div>
</Layout>
