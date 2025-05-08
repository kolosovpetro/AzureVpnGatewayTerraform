provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  subscription_id = "f32f6566-8fa0-4198-9c91-a3b8ac69e89a"
}
