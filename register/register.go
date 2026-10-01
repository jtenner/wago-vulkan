// Package register exposes the module's explicit Wago provider catalog.
package register

import (
	vulkan "github.com/jtenner/wago-vulkan"
	wago "github.com/wago-org/wago"
)

// Providers registers all three Vulkan namespaces with default options.
// Embedding hosts can use vulkan.Provider to select another memory or limit.
func Providers() []wago.PluginProvider {
	return []wago.PluginProvider{vulkan.Provider()}
}
