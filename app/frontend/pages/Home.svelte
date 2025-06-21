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
    Zap,
  } from "lucide-svelte";
  import { Link } from "@inertiajs/svelte";
  import * as Card from "$lib/components/ui/card/index.js";
  import Badge from "$lib/components/ui/badge/badge.svelte";

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
      name: "Adobe Creative Cloud",
      cost: "$52.99",
      users: "3 people",
      savings: "$35/month each",
      logo: "🎨",
    },
    {
      name: "Notion Team",
      cost: "$16.00",
      users: "4 people",
      savings: "$12/month each",
      logo: "📝",
    },
    {
      name: "Spotify Family",
      cost: "$16.99",
      users: "6 people",
      savings: "$7/month each",
      logo: "🎵",
    },
    {
      name: "Figma Professional",
      cost: "$24.00",
      users: "2 people",
      savings: "$12/month each",
      logo: "🎯",
    },
  ];
</script>

<svelte:head>
  <title>SplitSub - Split Subscription Costs with Friends</title>
  <meta
    name="description"
    content="Share and manage recurring subscriptions with friends and family. Split costs automatically and never miss a payment with Splitsub."
  />
</svelte:head>

<Layout>
  <!-- Hero Section -->
  <div
    class="relative bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-100 border-b overflow-hidden"
  >
    <!-- Background decoration -->
    <div
      class="absolute inset-0 bg-grid-slate-100 [mask-image:linear-gradient(0deg,#fff,rgba(255,255,255,0.6))]"
    ></div>
    <div
      class="absolute left-1/2 top-0 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-gradient-to-br from-blue-400/20 to-indigo-400/20 rounded-full blur-3xl"
    ></div>

    <div
      class="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 pt-16 sm:pt-20 lg:pt-24 pb-20 sm:pb-28 lg:pb-32"
    >
      <div class="text-center">
        <!-- Hero badge -->
        <div class="mb-6 flex justify-center">
          <Badge variant="secondary" class="px-4 py-2 text-sm font-medium">
            <Zap class="mr-2 h-4 w-4" />
            100% Free Forever
          </Badge>
        </div>

        <h1
          class="text-4xl sm:text-5xl lg:text-6xl xl:text-7xl font-bold tracking-tight text-slate-900 mb-6"
        >
          Split Subscriptions,
          <span
            class="bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent"
          >
            Save Money
          </span>
        </h1>

        <p
          class="mt-6 text-lg sm:text-xl leading-8 text-slate-600 max-w-3xl mx-auto"
        >
          Share Netflix, Spotify, and other SaaS subscriptions with friends and
          family. Automatically split costs, track payments, and never miss a
          bill again.
        </p>

        <div
          class="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4 sm:gap-6"
        >
          <Link
            href="/signup"
            class={buttonVariants({
              variant: "default",
              size: "lg",
              class:
                "h-12 px-8 text-base font-semibold shadow-lg hover:shadow-xl transition-all duration-200",
            })}
          >
            Get Started Free
            <ArrowRight class="ml-2 h-5 w-5" />
          </Link>
          <Link
            href="/login"
            class={buttonVariants({
              variant: "outline",
              size: "lg",
              class: "h-12 px-8 text-base font-semibold",
            })}
          >
            Sign In
          </Link>
        </div>
      </div>
    </div>
  </div>

  <!-- Popular Subscriptions Section -->
  <div class="py-20 sm:py-24 lg:py-28 bg-white">
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div class="text-center mb-16">
        <h2
          class="text-3xl sm:text-4xl lg:text-5xl font-bold tracking-tight text-slate-900 mb-4"
        >
          Popular Subscriptions to Split
        </h2>
        <p class="text-lg sm:text-xl text-slate-600 max-w-3xl mx-auto">
          From creative tools to productivity apps - see how much you could save
          by sharing these services
        </p>
      </div>

      <div class="grid gap-6 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
        {#each popularSubscriptions as sub}
          <Card.Root
            class="group hover:shadow-lg transition-all duration-200 border-0 shadow-sm bg-gradient-to-br from-white to-slate-50"
          >
            <Card.Header class="text-center pb-4">
              <div class="text-4xl mb-3">{sub.logo}</div>
              <Card.Title class="text-xl font-semibold">{sub.name}</Card.Title>
              <div class="text-2xl font-bold text-blue-600 mt-2">
                {sub.cost}
              </div>
            </Card.Header>
            <Card.Content class="pt-0">
              <div class="space-y-3">
                <div
                  class="flex items-center justify-center gap-2 text-sm text-slate-600"
                >
                  <Users class="h-4 w-4" />
                  <span>{sub.users}</span>
                </div>
                <div
                  class="flex items-center justify-center gap-2 text-sm font-semibold text-emerald-600 bg-emerald-50 rounded-full py-2 px-4"
                >
                  <DollarSign class="h-4 w-4" />
                  <span>Save {sub.savings}</span>
                </div>
              </div>
            </Card.Content>
          </Card.Root>
        {/each}
      </div>

      <div class="text-center mt-12">
        <Link
          href="/signup"
          class={buttonVariants({
            variant: "outline",
            size: "lg",
            class: "h-12 px-8 text-base font-semibold",
          })}
        >
          Start Splitting Now
          <ArrowRight class="ml-2 h-5 w-5" />
        </Link>
      </div>
    </div>
  </div>

  <!-- Features Section -->
  <div id="features" class="py-20 sm:py-24 lg:py-28 bg-slate-50">
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div class="text-center mb-16">
        <h2
          class="text-3xl sm:text-4xl lg:text-5xl font-bold tracking-tight text-slate-900 mb-4"
        >
          Everything You Need
        </h2>
        <p class="text-lg sm:text-xl text-slate-600 max-w-3xl mx-auto">
          Powerful features that make sharing subscriptions simple, secure, and
          stress-free
        </p>
      </div>

      <div class="grid gap-8 grid-cols-1 sm:grid-cols-2 lg:grid-cols-3">
        {#each features as feature}
          <Card.Root
            class="group hover:shadow-lg transition-all duration-200 border-0 shadow-sm bg-white"
          >
            <Card.Header class="text-center pb-4">
              <div
                class="mx-auto w-14 h-14 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform duration-200"
              >
                <svelte:component
                  this={feature.icon}
                  class="h-7 w-7 text-white"
                />
              </div>
              <Card.Title class="text-xl font-semibold mb-3"
                >{feature.title}</Card.Title
              >
              <Card.Description
                class="text-base text-slate-600 leading-relaxed"
              >
                {feature.description}
              </Card.Description>
            </Card.Header>
          </Card.Root>
        {/each}
      </div>
    </div>
  </div>

  <!-- How It Works Section -->
  <div id="how-it-works" class="py-20 sm:py-24 lg:py-28 bg-white">
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div class="text-center mb-16">
        <h2
          class="text-3xl sm:text-4xl lg:text-5xl font-bold tracking-tight text-slate-900 mb-4"
        >
          How It Works
        </h2>
        <p class="text-lg sm:text-xl text-slate-600 max-w-3xl mx-auto">
          Get started in minutes with our simple 4-step process
        </p>
      </div>

      <div class="grid gap-8 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
        {#each [{ title: "Create Project", description: "Set up a new subscription project with details like cost and billing cycle." }, { title: "Invite Friends", description: "Send email invitations to friends and family you want to share with." }, { title: "Track Payments", description: "Upload receipts and mark payments as complete when members pay their share." }, { title: "Get Reminders", description: "Receive automated email reminders before payments are due." }] as step, index}
          <div class="text-center relative">
            {#if index < 3}
              <div
                class="hidden lg:block absolute top-8 left-full w-full h-0.5 bg-gradient-to-r from-blue-200 to-indigo-200 -translate-y-1/2"
              ></div>
            {/if}
            <div
              class="relative mx-auto w-16 h-16 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-2xl flex items-center justify-center text-white font-bold text-xl mb-6 shadow-lg"
            >
              {index + 1}
            </div>
            <h3 class="text-lg font-semibold mb-3 text-slate-900">
              {step.title}
            </h3>
            <p class="text-base text-slate-600 leading-relaxed">
              {step.description}
            </p>
          </div>
        {/each}
      </div>
    </div>
  </div>

  <!-- Pricing Section -->
  <div id="pricing" class="py-20 sm:py-24 lg:py-28 bg-slate-50">
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div class="text-center mb-16">
        <h2
          class="text-3xl sm:text-4xl lg:text-5xl font-bold tracking-tight text-slate-900 mb-4"
        >
          Simple, Transparent Pricing
        </h2>
        <p class="text-lg sm:text-xl text-slate-600 max-w-3xl mx-auto">
          SplitSub is completely free to use. No hidden fees, no subscriptions,
          no credit card required.
        </p>
      </div>

      <div class="max-w-lg mx-auto">
        <Card.Root
          class="border-0 shadow-xl bg-gradient-to-br from-white to-slate-50"
        >
          <Card.Header class="text-center pb-6">
            <Badge variant="secondary" class="mb-4 px-3 py-1">
              Most Popular
            </Badge>
            <Card.Title class="text-2xl font-bold mb-2">Free Forever</Card.Title
            >
            <div class="flex items-center justify-center mb-2">
              <span class="text-5xl font-bold text-slate-900">$0</span>
              <span class="text-lg text-slate-500 ml-2">/month</span>
            </div>
            <Card.Description class="text-base"
              >Perfect for everyone</Card.Description
            >
          </Card.Header>
          <Card.Content class="pb-8">
            <div class="space-y-4 mb-8">
              {#each ["Unlimited subscription projects", "Unlimited group members", "Payment tracking & reminders", "Receipt uploads & storage", "Email notifications", "Magic link authentication", "Mobile-friendly interface", "24/7 support"] as feature}
                <div class="flex items-center gap-3">
                  <CheckCircle class="h-5 w-5 text-emerald-500 flex-shrink-0" />
                  <span class="text-slate-700">{feature}</span>
                </div>
              {/each}
            </div>
            <Link
              href="/signup"
              class={buttonVariants({
                variant: "default",
                size: "lg",
                class:
                  "w-full h-12 text-base font-semibold shadow-lg hover:shadow-xl transition-all duration-200",
              })}
            >
              Get Started Free
              <ArrowRight class="ml-2 h-5 w-5" />
            </Link>
          </Card.Content>
        </Card.Root>
      </div>
    </div>
  </div>

  <!-- CTA Section -->
  <div
    class="relative bg-gradient-to-r from-blue-600 to-indigo-700 overflow-hidden"
  >
    <div
      class="absolute inset-0 bg-grid-white/10 [mask-image:linear-gradient(0deg,#fff,rgba(255,255,255,0.6))]"
    ></div>
    <div
      class="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-20 sm:py-24 text-center"
    >
      <h2
        class="text-3xl sm:text-4xl lg:text-5xl font-bold tracking-tight text-white mb-6"
      >
        Ready to Start Saving?
      </h2>
      <p class="text-lg sm:text-xl text-blue-100 max-w-3xl mx-auto mb-10">
        Join users who are splitting subscriptions and saving money every month.
      </p>
      <div
        class="flex flex-col sm:flex-row items-center justify-center gap-4 sm:gap-6"
      >
        <Link
          href="/signup"
          class={buttonVariants({
            variant: "secondary",
            size: "lg",
            class:
              "h-12 px-8 text-base font-semibold shadow-lg hover:shadow-xl transition-all duration-200",
          })}
        >
          Get Started Free
          <ArrowRight class="ml-2 h-5 w-5" />
        </Link>
        <Link
          href="/login"
          class={buttonVariants({
            variant: "ghost",
            size: "lg",
            class:
              "h-12 px-8 text-base font-semibold text-white hover:bg-white/10",
          })}
        >
          Sign In
        </Link>
      </div>
      <p class="mt-6 text-sm text-blue-200">
        No credit card required • Free forever • Start in 30 seconds
      </p>
    </div>
  </div>
</Layout>
