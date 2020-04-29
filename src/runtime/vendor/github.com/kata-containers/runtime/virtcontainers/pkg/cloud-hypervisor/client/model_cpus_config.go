/*
 * Cloud Hypervisor API
 *
 * Local HTTP based API for managing and inspecting a cloud-hypervisor virtual machine.
 *
 * API version: 0.3.0
 * Generated by: OpenAPI Generator (https://openapi-generator.tech)
 */

package openapi
// CpusConfig struct for CpusConfig
type CpusConfig struct {
	BootVcpus int32 `json:"boot_vcpus"`
	MaxVcpus int32 `json:"max_vcpus"`
}