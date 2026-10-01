package register

import (
	"bytes"
	"os"
	"testing"

	vulkan "github.com/jtenner/wago-vulkan"
	wago "github.com/wago-org/wago"
)

func TestProviderCatalog(t *testing.T) {
	providers := Providers()
	if len(providers) != 1 || providers[0].Definition.ID != vulkan.PluginID || providers[0].New == nil {
		t.Fatalf("unexpected registry providers: %#v", providers)
	}
	want, err := wago.EncodeProviderCatalog(vulkan.PluginID+"/register", providers)
	if err != nil {
		t.Fatal(err)
	}
	got, err := os.ReadFile("../wago.providers.json")
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(got, want) {
		t.Fatal("stale wago.providers.json; run: wago plugin catalog")
	}
}
