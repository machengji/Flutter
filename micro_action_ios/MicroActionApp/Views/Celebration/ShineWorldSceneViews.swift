import SwiftUI

/// 4 大微步治愈世界形态（与 4 季色盘组合形成 16 种不重样画卷）
enum ShineWorldScene: Int, CaseIterable, Identifiable {
    case growthTree = 0          // 成长树
    case starryLanternSea = 1    // 星海星灯
    case crystalTerrarium = 2    // 水晶生态瓶
    case auroraConstellation = 3 // 极光星座图

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .growthTree: return "成长树"
        case .starryLanternSea: return "星海灯"
        case .crystalTerrarium: return "生态瓶"
        case .auroraConstellation: return "星座图"
        }
    }

    var iconName: String {
        switch self {
        case .growthTree: return "leaf.fill"
        case .starryLanternSea: return "flame.fill"
        case .crystalTerrarium: return "sparkles"
        case .auroraConstellation: return "star.fill"
        }
    }

    var waterActionLabel: String {
        switch self {
        case .growthTree: return "按住浇灌"
        case .starryLanternSea: return "按住放飞星灯"
        case .crystalTerrarium: return "按住投入星籽"
        case .auroraConstellation: return "按住点亮星辰"
        }
    }

    var isDarkCanvas: Bool {
        switch self {
        case .growthTree: return false
        case .starryLanternSea, .crystalTerrarium, .auroraConstellation: return true
        }
    }
}

/// 4 季氛围色盘（每 4 卷推进一季，4 大世界 × 4 季色盘 = 16 种不重样画卷）
enum ShineSeasonPalette: Int, CaseIterable {
    case springSakura = 0
    case summerAzure = 1
    case autumnGinkgo = 2
    case winterAurora = 3

    static func forVolume(_ volumeIndex: Int) -> ShineSeasonPalette {
        let idx = (max(0, volumeIndex) / 4) % allCases.count
        return ShineSeasonPalette(rawValue: idx) ?? .springSakura
    }

    var seasonTitle: String {
        switch self {
        case .springSakura: return "春岚"
        case .summerAzure: return "夏汐"
        case .autumnGinkgo: return "秋鎏"
        case .winterAurora: return "冬极"
        }
    }

    var skyTop: Color {
        switch self {
        case .springSakura: return Color(hex: 0x161D38)
        case .summerAzure: return Color(hex: 0x0B2438)
        case .autumnGinkgo: return Color(hex: 0x1F182C)
        case .winterAurora: return Color(hex: 0x091624)
        }
    }

    var skyMid: Color {
        switch self {
        case .springSakura: return Color(hex: 0x2B2F56)
        case .summerAzure: return Color(hex: 0x124559)
        case .autumnGinkgo: return Color(hex: 0x422B3E)
        case .winterAurora: return Color(hex: 0x143342)
        }
    }

    var skyBottom: Color {
        switch self {
        case .springSakura: return Color(hex: 0x4B3E5E)
        case .summerAzure: return Color(hex: 0x1E6070)
        case .autumnGinkgo: return Color(hex: 0x6B4346)
        case .winterAurora: return Color(hex: 0x1C4D52)
        }
    }

    var glowPrimary: Color {
        switch self {
        case .springSakura: return Color(hex: 0xFFD49E)
        case .summerAzure: return Color(hex: 0x8CE8D6)
        case .autumnGinkgo: return Color(hex: 0xFFC764)
        case .winterAurora: return Color(hex: 0x8CC8FF)
        }
    }

    var glowSecondary: Color {
        switch self {
        case .springSakura: return Color(hex: 0xF7A8C4)
        case .summerAzure: return Color(hex: 0xFFE38F)
        case .autumnGinkgo: return Color(hex: 0xF59668)
        case .winterAurora: return Color(hex: 0x99F3D0)
        }
    }
}

// MARK: - 场景 2：星海放飞星灯画卷（每 1 步 = 一盏暖光摇曳升空的星灯 + 海面星光倒影）

struct StarryLanternSeaSceneView: View {
    let records: [ShineRecord]
    let palette: ShineSeasonPalette
    let newestIndex: Int?
    let onSelectRecord: (ShineRecord) -> Void

    @State private var floatPhase: Bool = false

    private var visibleRecords: [ShineRecord] { Array(records.prefix(100)) }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let horizonY = h * 0.77

            ZStack {
                // 1. 沉浸式深海夜空渐变
                LinearGradient(
                    colors: [palette.skyTop, palette.skyMid, palette.skyBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // 2. 背景微弱繁星点缀
                Canvas { ctx, size in
                    for i in 0..<42 {
                        let sx = size.width * CGFloat(((i * 37 + 13) % 94) + 3) / 100.0
                        let sy = size.height * CGFloat(((i * 29 + 7) % 66) + 5) / 100.0
                        let r: CGFloat = (i % 3 == 0) ? 1.8 : 1.1
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: sx, y: sy, width: r * 2, height: r * 2)),
                            with: .color(Color.white.opacity(i % 2 == 0 ? 0.45 : 0.22))
                        )
                    }
                }
                .allowsHitTesting(false)

                // 3. 远方海平线与柔和灯辉倒影
                VStack(spacing: 0) {
                    Spacer()
                    ZStack {
                        LinearGradient(
                            colors: [
                                palette.skyBottom.opacity(0.65),
                                palette.skyTop.opacity(0.92)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        // 暖金海面反光波纹
                        Ellipse()
                            .fill(
                                RadialGradient(
                                    colors: [palette.glowPrimary.opacity(0.32), .clear],
                                    center: .center,
                                    startRadius: 8,
                                    endRadius: w * 0.48
                                )
                            )
                            .frame(width: w * 0.85, height: 64)
                            .offset(y: -h * 0.06)
                    }
                    .frame(height: h - horizonY)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)

                // 4. 逐盏放飞的发光星灯（1 次微步 = 1 盏星灯）
                ForEach(Array(visibleRecords.enumerated()), id: \.element.id) { idx, rec in
                    let pos = lanternPosition(index: idx, width: w, height: h)
                    let isNewest = (newestIndex == idx)
                    let lanternScale = 0.62 + (pos.depth * 0.48)
                    let driftY: CGFloat = floatPhase ? -7.5 * pos.depth : 6.5 * pos.depth
                    let tint = (idx % 3 == 0) ? palette.glowPrimary : ((idx % 3 == 1) ? palette.glowSecondary : Color(hex: 0xFFE6A8))

                    Button {
                        onSelectRecord(rec)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [tint.opacity(isNewest ? 0.68 : 0.42), .clear],
                                        center: .center,
                                        startRadius: 2,
                                        endRadius: 24 * lanternScale
                                    )
                                )
                                .frame(width: 48 * lanternScale, height: 48 * lanternScale)

                            RoundedRectangle(cornerRadius: 6 * lanternScale, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: 0xFFFDF5), tint],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(width: 15 * lanternScale, height: 21 * lanternScale)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6 * lanternScale, style: .continuous)
                                        .stroke(Color.white.opacity(0.45), lineWidth: 0.7)
                                )
                                .shadow(color: tint.opacity(0.8), radius: 6)
                        }
                    }
                    .buttonStyle(.plain)
                    .position(x: pos.x, y: pos.y + driftY)
                }

                if visibleRecords.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 30))
                            .foregroundColor(palette.glowPrimary.opacity(0.85))
                        Text("完成第一步，在星海放飞你的第一盏星灯")
                            .font(.system(size: 13.5, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.75))
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.6).repeatForever(autoreverses: true)) {
                floatPhase = true
            }
        }
    }

    private func lanternPosition(index: Int, width: CGFloat, height: CGFloat) -> (x: CGFloat, y: CGFloat, depth: CGFloat) {
        let k = Double(index + 1)
        let golden = k * 2.3999632297
        let nx = 0.50 + cos(golden) * 0.39 * sqrt(min(1.0, k / 95.0))
        let ny = 0.70 - (Double(index % 25) / 25.0) * 0.48 - sin(k * 1.9) * 0.04
        let depth = CGFloat(0.45 + (Double((index * 17) % 10) / 10.0) * 0.55)
        return (
            x: max(28, min(width - 28, width * CGFloat(nx))),
            y: max(height * 0.17, min(height * 0.73, height * CGFloat(ny))),
            depth: depth
        )
    }
}

// MARK: - 场景 3：发光水晶生态瓶（每 1 步 = 落入瓶中一颗晶莹发光星籽，100 颗满瓶生辉）

struct CrystalTerrariumSceneView: View {
    let records: [ShineRecord]
    let palette: ShineSeasonPalette
    let newestIndex: Int?
    let onSelectRecord: (ShineRecord) -> Void

    @State private var shimmer: Bool = false

    private var visibleRecords: [ShineRecord] { Array(records.prefix(100)) }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let jarW = min(w * 0.72, 290)
            let jarH = min(h * 0.50, 390)

            ZStack {
                LinearGradient(
                    colors: [palette.skyTop, palette.skyMid, palette.skyTop],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // 瓶后柔光光晕
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [palette.glowPrimary.opacity(0.28), palette.glowSecondary.opacity(0.12), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: jarW * 0.95
                        )
                    )
                    .frame(width: jarW * 1.7, height: jarW * 1.7)
                    .position(x: w / 2, y: h * 0.52)

                // 居中生态玻璃瓶主体
                ZStack {
                    // 软木塞瓶盖
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0xD9A979), Color(hex: 0xA87449)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: jarW * 0.44, height: 34)
                        .offset(y: -jarH / 2 - 14)

                    // 瓶颈玻璃环
                    Capsule()
                        .fill(Color.white.opacity(0.22))
                        .overlay(Capsule().stroke(Color.white.opacity(0.55), lineWidth: 1.4))
                        .frame(width: jarW * 0.56, height: 22)
                        .offset(y: -jarH / 2 + 2)

                    // 通透玻璃瓶身
                    RoundedRectangle(cornerRadius: jarW * 0.24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.16),
                                    Color.white.opacity(0.06),
                                    palette.glowPrimary.opacity(0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: jarW, height: jarH)
                        .overlay(
                            RoundedRectangle(cornerRadius: jarW * 0.24, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.65), Color.white.opacity(0.18), Color.white.opacity(0.45)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2.0
                                )
                        )

                    // 瓶内发光水晶星籽（从瓶底逐层堆满 100 颗）
                    ZStack {
                        ForEach(Array(visibleRecords.enumerated()), id: \.element.id) { idx, rec in
                            let pos = gemPosition(index: idx, jarW: jarW, jarH: jarH)
                            let isNewest = (newestIndex == idx)
                            let colors: [Color] = [
                                palette.glowPrimary,
                                palette.glowSecondary,
                                Color(hex: 0xFFF3B0),
                                Color(hex: 0xA5F3FC),
                                Color(hex: 0xFBCFE8)
                            ]
                            let gemColor = colors[idx % colors.count]

                            Button {
                                onSelectRecord(rec)
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                colors: [Color.white.opacity(0.95), gemColor, gemColor.opacity(0.45)],
                                                center: .topLeading,
                                                startRadius: 1,
                                                endRadius: 14
                                            )
                                        )
                                        .frame(width: pos.size, height: pos.size)
                                        .shadow(color: gemColor.opacity(shimmer ? 0.9 : 0.45), radius: isNewest ? 10 : 5)
                                }
                            }
                            .buttonStyle(.plain)
                            .position(x: pos.x, y: pos.y)
                        }
                    }
                    .frame(width: jarW, height: jarH)
                    .clipShape(RoundedRectangle(cornerRadius: jarW * 0.23, style: .continuous))

                    // 玻璃高光反光弧线
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.28))
                        .frame(width: 9, height: jarH * 0.56)
                        .offset(x: -jarW * 0.36, y: -jarH * 0.04)
                        .allowsHitTesting(false)
                }
                .position(x: w / 2, y: h * 0.53)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
    }

    private func gemPosition(index: Int, jarW: CGFloat, jarH: CGFloat) -> (x: CGFloat, y: CGFloat, size: CGFloat) {
        let cols = 8
        let row = index / cols
        let col = index % cols
        let cellW = (jarW - 38) / CGFloat(cols)
        let rowStep: CGFloat = (jarH - 52) / 13.0
        let jitterX = CGFloat(((index * 19) % 9) - 4) * 1.4
        let jitterY = CGFloat(((index * 13) % 7) - 3) * 1.1
        let x = 22 + (CGFloat(col) + 0.5) * cellW + (row % 2 == 1 ? cellW * 0.28 : -cellW * 0.14) + jitterX
        let y = (jarH - 24) - CGFloat(row) * rowStep + jitterY
        let size = CGFloat(20 + (index * 7) % 7)
        return (x: max(22, min(jarW - 22, x)), y: max(28, min(jarH - 22, y)), size: size)
    }
}

// MARK: - 场景 4：极光星座星图（每 1 步 = 点亮一颗星辰，纤细金线自动连成专属星系）

struct AuroraConstellationSceneView: View {
    let records: [ShineRecord]
    let palette: ShineSeasonPalette
    let newestIndex: Int?
    let onSelectRecord: (ShineRecord) -> Void

    @State private var twinkle: Bool = false

    private var visibleRecords: [ShineRecord] { Array(records.prefix(100)) }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let points = (0..<visibleRecords.count).map { starPoint(index: $0, width: w, height: h) }

            ZStack {
                LinearGradient(
                    colors: [palette.skyTop, palette.skyMid, palette.skyTop],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // 流动极光幕布
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [palette.glowSecondary.opacity(0.28), palette.glowPrimary.opacity(0.20), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: w * 1.25, height: h * 0.34)
                    .rotationEffect(.degrees(-14))
                    .blur(radius: 36)
                    .offset(y: -h * 0.14)
                    .allowsHitTesting(false)

                // 星盘微弱同心星轨
                ForEach([0.36, 0.58, 0.80], id: \.self) { ratio in
                    Circle()
                        .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 0.8, dash: [4, 6]))
                        .frame(width: w * ratio, height: w * ratio)
                        .position(x: w / 2, y: h * 0.48)
                }
                .allowsHitTesting(false)

                // 鎏金星座连线
                Canvas { ctx, _ in
                    guard points.count >= 2 else { return }
                    var path = Path()
                    for i in 1..<points.count {
                        // 每 12 颗星组成一座独立小星座，避免线条过度杂乱
                        if i % 12 == 0 { continue }
                        path.move(to: points[i - 1])
                        path.addLine(to: points[i])
                    }
                    ctx.stroke(
                        path,
                        with: .color(palette.glowPrimary.opacity(0.32)),
                        lineWidth: 0.9
                    )
                }
                .allowsHitTesting(false)

                // 逐颗点亮的璀璨星辰
                ForEach(Array(visibleRecords.enumerated()), id: \.element.id) { idx, rec in
                    let pt = points[idx]
                    let isNewest = (newestIndex == idx)
                    let isMajor = (idx % 5 == 0)
                    let starColor = (idx % 2 == 0) ? palette.glowPrimary : Color(hex: 0xFFFDF2)

                    Button {
                        onSelectRecord(rec)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(starColor.opacity(twinkle ? 0.38 : 0.16))
                                .frame(width: isMajor ? 24 : 16, height: isMajor ? 24 : 16)
                            Image(systemName: isMajor ? "sparkle" : "star.fill")
                                .font(.system(size: isMajor ? 13 : 8.5, weight: .bold))
                                .foregroundColor(starColor)
                                .shadow(color: starColor.opacity(0.9), radius: isNewest ? 8 : 4)
                        }
                    }
                    .buttonStyle(.plain)
                    .position(pt)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                twinkle = true
            }
        }
    }

    private func starPoint(index: Int, width: CGFloat, height: CGFloat) -> CGPoint {
        let k = Double(index + 1)
        let golden = k * 2.3999632297
        let r = sqrt(k / 100.0)
        let maxR = min(width * 0.41, height * 0.28)
        let x = width * 0.50 + CGFloat(cos(golden)) * maxR * CGFloat(r)
        let y = height * 0.48 + CGFloat(sin(golden)) * maxR * 1.15 * CGFloat(r)
        return CGPoint(x: x, y: y)
    }
}
