class PagesController < ApplicationController
  allow_unauthenticated_access

  def home
    if authenticated?
      redirect_to dashboard_path
    else
      # Set meta tags for home page
      content_for :title, "SplitMySub - Split Subscription Costs with Friends"
      content_for :description, "Share and manage recurring subscriptions with friends and family. Split costs automatically and never miss a payment with SplitMySub."
      content_for :og_title, "SplitMySub - Split Subscription Costs with Friends"
      content_for :og_description, "Share Netflix, Spotify, and other SaaS subscriptions with friends and family. Automatically split costs, track payments, and never miss a bill again."
      content_for :og_url, root_url
      content_for :canonical_url, root_url

      render inertia: "Home"
    end
  end

  def create_flash
    flash[:notice] = "This is a notice"
    flash[:alert] = "This is an alert"
    flash[:error] = "This is an error"
    redirect_to root_path
  end
end
