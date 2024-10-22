package test

import (
	"context"
	"log"
	"os"
	"strconv"
	"testing"

	"github.com/digitalocean/godo"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/joho/godotenv"
	"github.com/stretchr/testify/assert"
	"golang.org/x/oauth2"
)

const envVar string = "CICD_RO_TOKEN"

func digitalOceanApiAuth(envVar string) *godo.Client {
	if os.Getenv("GITHUB_ACTIONS") != "" {
		err := godotenv.Load("digital_ocean.env")
		if err != nil {
			log.Fatalln("terminating due to godotenv error:", err)
		}
	}

	digitalOceanToken := oauth2.StaticTokenSource(&oauth2.Token{
		AccessToken: os.Getenv(envVar),
	})
	oauthClient := oauth2.NewClient(context.Background(), digitalOceanToken)
	client := godo.NewClient(oauthClient)
	return client
}

func TestMiabDigitalOceanDroplet(t *testing.T) {
	doClient := digitalOceanApiAuth("CICD_RO_TOKEN")
	terraformOpts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"droplet_size":  "s-1vcpu-1gb",
			"droplet_image": "ubuntu-22-04-x64",
		},
	})

	defer terraform.Destroy(t, terraformOpts)
	terraform.InitAndApply(t, terraformOpts)

	dropletId, tfOutputErr := terraform.OutputE(t, terraformOpts, "droplet_id")
	assert.Nil(t, tfOutputErr)

	idInt, conversionErr := strconv.Atoi(dropletId)
	assert.Nil(t, conversionErr)
	assert.NotNil(t, dropletId)
	assert.Equal(t, 9, len(dropletId))

	droplet, _, conversionErr := doClient.Droplets.Get(context.Background(), idInt)
	assert.EqualValues(t, terraformOpts.Vars["droplet_size"].(string), droplet.SizeSlug)
	assert.EqualValues(t, terraformOpts.Vars["droplet_image"].(string), droplet.Image.Name)
}
