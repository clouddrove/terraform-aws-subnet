// Managed By : CloudDrove
// Description : This Terratest is used to test the Terraform public subnet module.
// Copyright @ CloudDrove. All Right Reserved.
package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func Test(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../_example/public-subnet",
		Upgrade:      true,
	}

	// This will run 'terraform init' and 'terraform application' and will fail the test if any errors occur
	terraform.InitAndApply(t, terraformOptions)

	// To clean up any resources that have been created, run 'terraform destroy' towards the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// To get the value of an output variable, run 'terraform output'
	publicTags := terraform.OutputMap(t, terraformOptions, "public_tags")

	//Expected Values

	// Check that we get back the outputs that we expect
	assert.Equal(t, "subnets-test-public", publicTags["Name"])
}
