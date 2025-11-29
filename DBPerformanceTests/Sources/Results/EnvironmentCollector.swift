import Foundation

#if os(macOS)
import IOKit
#endif

/// 시스템 환경 정보 수집
struct EnvironmentCollector {
    nonisolated static func collect() -> BenchmarkResult.EnvironmentInfo {
        BenchmarkResult.EnvironmentInfo(
            cpuModel: getCPUModel(),
            cpuCores: ProcessInfo.processInfo.processorCount,
            ramSize: getRAMSize(),
            diskType: "SSD", // 간소화
            macOSVersion: getMacOSVersion(),
            swiftVersion: getSwiftVersion(),
            xcodeVersion: "16.0", // 간소화
            cpuUsage: getCPUUsage(),
            memoryUsage: getMemoryUsage(),
            diskUsage: 0.0 // 간소화
        )
    }

    private static func getCPUModel() -> String {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &machine, &size, nil, 0)
        return String(cString: machine)
    }

    private static func getRAMSize() -> Double {
        let bytes = ProcessInfo.processInfo.physicalMemory
        return Double(bytes) / 1_073_741_824.0 // Bytes to GB
    }

    private static func getMacOSVersion() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    private static func getSwiftVersion() -> String {
        #if swift(>=6.0)
        return "6.0"
        #elseif swift(>=5.9)
        return "5.9"
        #else
        return "Unknown"
        #endif
    }

    private static func getCPUUsage() -> Double {
        var cpuInfo: processor_info_array_t!
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCPUs: natural_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &numCpuInfo
        )

        guard result == KERN_SUCCESS else { return 0.0 }

        var totalUsage: Double = 0.0

        for i in 0..<Int(numCPUs) {
            let offset = Int(CPU_STATE_MAX) * i
            let user = Double(cpuInfo[offset + Int(CPU_STATE_USER)])
            let system = Double(cpuInfo[offset + Int(CPU_STATE_SYSTEM)])
            let idle = Double(cpuInfo[offset + Int(CPU_STATE_IDLE)])
            let nice = Double(cpuInfo[offset + Int(CPU_STATE_NICE)])

            let total = user + system + idle + nice
            if total > 0 {
                totalUsage += ((user + system + nice) / total) * 100.0
            }
        }

        return totalUsage / Double(numCPUs)
    }

    private static func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }

        guard result == KERN_SUCCESS else { return 0.0 }

        let usedMemory = Double(info.resident_size)
        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)

        return (usedMemory / totalMemory) * 100.0
    }
}
