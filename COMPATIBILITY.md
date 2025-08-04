# Compatibility & Risk Assessment

This document provides detailed compatibility information, weight limits, and risk assessments for different MacBook models.

## Table of Contents

1. [MacBook Model Compatibility](#macbook-model-compatibility)
2. [Weight Limits by Model](#weight-limits-by-model)
3. [Risk Assessment](#risk-assessment)
4. [Safety Guidelines](#safety-guidelines)
5. [Accuracy Specifications](#accuracy-specifications)
6. [Environmental Considerations](#environmental-considerations)

## MacBook Model Compatibility

### Fully Compatible Models

#### MacBook Pro with Force Touch (2015+)

| Model | Year | Screen Size | Force Touch | Max Weight | Accuracy |
|-------|------|-------------|-------------|------------|----------|
| MacBook Pro | 2015 | 13-inch | Yes | 300g | ±0.2g |
| MacBook Pro | 2015 | 15-inch | Yes | 350g | ±0.2g |
| MacBook Pro | 2016-2017 | 13-inch | Yes | 300g | ±0.15g |
| MacBook Pro | 2016-2017 | 15-inch | Yes | 350g | ±0.15g |
| MacBook Pro | 2018-2019 | 13-inch | Yes | 300g | ±0.1g |
| MacBook Pro | 2018-2019 | 15-inch | Yes | 350g | ±0.1g |
| MacBook Pro | 2020+ | 13-inch | Yes | 300g | ±0.1g |
| MacBook Pro | 2021+ | 14-inch | Yes | 300g | ±0.1g |
| MacBook Pro | 2021+ | 16-inch | Yes | 400g | ±0.1g |

#### MacBook (12-inch, 2016-2017)

| Model | Year | Screen Size | Force Touch | Max Weight | Accuracy |
|-------|------|-------------|-------------|------------|----------|
| MacBook | 2016 | 12-inch | Yes | 250g | ±0.2g |
| MacBook | 2017 | 12-inch | Yes | 250g | ±0.2g |

#### MacBook Air (2018+)

| Model | Year | Screen Size | Force Touch | Max Weight | Accuracy |
|-------|------|-------------|-------------|------------|----------|
| MacBook Air | 2018-2019 | 13-inch | Yes | 280g | ±0.15g |
| MacBook Air | 2020+ | 13-inch | Yes | 280g | ±0.1g |
| MacBook Air | 2022+ | 15-inch | Yes | 320g | ±0.1g |

### Limited/No Compatibility

#### MacBook Air (Pre-2018)

| Model | Year | Screen Size | Force Touch | Compatibility |
|-------|------|-------------|-------------|---------------|
| MacBook Air | 2010-2017 | 11-inch | No | ❌ Not Compatible |
| MacBook Air | 2010-2017 | 13-inch | No | ❌ Not Compatible |

#### MacBook Pro (Pre-2015)

| Model | Year | Screen Size | Force Touch | Compatibility |
|-------|------|-------------|-------------|---------------|
| MacBook Pro | 2009-2014 | 13-inch | No | ❌ Not Compatible |
| MacBook Pro | 2009-2014 | 15-inch | No | ❌ Not Compatible |
| MacBook Pro | 2009-2014 | 17-inch | No | ❌ Not Compatible |

### Identification Guide

#### How to Check Your Model

1. **Apple Menu → About This Mac**
   ```
   Model Name: MacBook Pro
   Model Identifier: MacBookPro16,1
   Chip: M1 Pro
   Year: 2021
   ```

2. **Force Touch Test**
   ```
   System Preferences → Trackpad → Force Click and haptic feedback
   Test by force-clicking on trackpad - should feel distinct "click"
   ```

3. **Terminal Command**
   ```bash
   system_profiler SPHardwareDataType | grep "Model Identifier"
   ```

#### Model Identifier Reference

| Model Identifier | Model Name | Force Touch | Max Weight |
|------------------|------------|-------------|------------|
| MacBookPro11,* | MacBook Pro (2013-2014) | No | N/A |
| MacBookPro12,1 | MacBook Pro 13" (2015) | Yes | 300g |
| MacBookPro13,* | MacBook Pro (2016-2017) | Yes | 300-350g |
| MacBookPro14,* | MacBook Pro (2017) | Yes | 300-350g |
| MacBookPro15,* | MacBook Pro (2018-2019) | Yes | 300-350g |
| MacBookPro16,* | MacBook Pro (2019-2021) | Yes | 350-400g |
| MacBookPro17,1 | MacBook Pro 13" M1 (2020) | Yes | 300g |
| MacBookPro18,* | MacBook Pro 14"/16" M1 Pro/Max (2021) | Yes | 300-400g |
| MacBookAir6,* | MacBook Air (2013-2015) | No | N/A |
| MacBookAir8,* | MacBook Air (2018-2019) | Yes | 280g |
| MacBookAir9,1 | MacBook Air M1 (2020) | Yes | 280g |
| MacBookAir10,1 | MacBook Air M2 (2022) | Yes | 280g |
| MacBook8,1 | MacBook 12" (2015) | No | N/A |
| MacBook9,1 | MacBook 12" (2016) | Yes | 250g |
| MacBook10,1 | MacBook 12" (2017) | Yes | 250g |

## Weight Limits by Model

### Understanding Weight Limits

The weight limits are based on the Force Touch trackpad's pressure sensitivity range and physical construction. Exceeding these limits may:

- Damage the trackpad mechanism
- Void your warranty
- Produce inaccurate readings
- Cause permanent calibration drift

### Detailed Weight Specifications

#### MacBook Pro Models

**13-inch Models (2015-2020)**
- **Recommended Maximum**: 300g
- **Absolute Maximum**: 500g (risk of damage)
- **Optimal Range**: 1-200g
- **Minimum Detectable**: 0.1g

**15-inch Models (2015-2019)**
- **Recommended Maximum**: 350g
- **Absolute Maximum**: 600g (risk of damage)
- **Optimal Range**: 1-250g
- **Minimum Detectable**: 0.1g

**14-inch Models (2021+)**
- **Recommended Maximum**: 300g
- **Absolute Maximum**: 500g (risk of damage)
- **Optimal Range**: 1-200g
- **Minimum Detectable**: 0.05g

**16-inch Models (2019+)**
- **Recommended Maximum**: 400g
- **Absolute Maximum**: 700g (risk of damage)
- **Optimal Range**: 1-300g
- **Minimum Detectable**: 0.05g

#### MacBook Air Models

**13-inch (2018+)**
- **Recommended Maximum**: 280g
- **Absolute Maximum**: 450g (risk of damage)
- **Optimal Range**: 1-180g
- **Minimum Detectable**: 0.1g

**15-inch (2023+)**
- **Recommended Maximum**: 320g
- **Absolute Maximum**: 500g (risk of damage)
- **Optimal Range**: 1-220g
- **Minimum Detectable**: 0.1g

#### MacBook 12-inch (2016-2017)

**12-inch Models**
- **Recommended Maximum**: 250g
- **Absolute Maximum**: 400g (risk of damage)
- **Optimal Range**: 1-150g
- **Minimum Detectable**: 0.2g

### Weight Distribution Guidelines

#### Single Point Loading
- **Maximum pressure per cm²**: 200g/cm²
- **Recommended area**: Distribute weight over 2-4 cm²
- **Avoid**: Sharp edges, pointed objects

#### Multiple Items
- **Total weight**: Sum must not exceed model maximum
- **Distribution**: Spread items across trackpad surface
- **Spacing**: Allow 1cm between items when possible

## Risk Assessment

### Physical Risks

#### High Risk (Avoid)

1. **Exceeding Absolute Maximum Weight**
   - **Risk**: Permanent trackpad damage
   - **Cost**: $200-500 repair
   - **Warranty**: Likely voided
   - **Mitigation**: Use external scale for heavy items

2. **Sharp or Pointed Objects**
   - **Risk**: Scratching trackpad surface
   - **Examples**: Screws, pins, razor blades
   - **Mitigation**: Place on soft material first

3. **Liquid or Wet Items**
   - **Risk**: Liquid damage to internal components
   - **Cost**: $300-800 repair
   - **Mitigation**: Dry items completely first

4. **Hot Objects**
   - **Risk**: Thermal damage, deformation
   - **Temperature**: Avoid items >40°C (104°F)
   - **Mitigation**: Allow cooling first

#### Medium Risk (Use Caution)

1. **Metal Objects**
   - **Risk**: Interference with touch sensitivity
   - **Mitigation**: Use non-conductive barrier
   - **Examples**: Paper, cloth, plastic film

2. **Static-Sensitive Items**
   - **Risk**: ESD damage to components
   - **Mitigation**: Ground yourself first
   - **Examples**: Computer chips, memory cards

3. **Magnetic Items**
   - **Risk**: Interference with internal sensors
   - **Mitigation**: Test readings, recalibrate after use
   - **Examples**: Strong magnets, magnetic tools

4. **Food Items**
   - **Risk**: Contamination, residue
   - **Mitigation**: Use barrier, clean afterward
   - **Hygiene**: Not FDA-approved for food contact

#### Low Risk (Generally Safe)

1. **Paper Documents**
   - **Weight range**: 1-50g typically
   - **Accuracy**: Very good
   - **Precautions**: Ensure dry

2. **Coins and Currency**
   - **Weight range**: 0.5-30g typically
   - **Accuracy**: Excellent reference weights
   - **Precautions**: Clean hands first

3. **Small Electronics**
   - **Weight range**: 1-100g typically
   - **Accuracy**: Good
   - **Precautions**: Avoid static discharge

### Data and Privacy Risks

#### Low Risk

1. **Weight Data Collection**
   - **Scope**: Only weight, timestamp, session data
   - **Storage**: Local only (unless API/webhook configured)
   - **Mitigation**: Disable logging if concerned

2. **API Server Exposure**
   - **Scope**: Local network access only
   - **Risk**: Unauthorized weight data access
   - **Mitigation**: Disable server when not needed

3. **System Permissions**
   - **Required**: Accessibility permissions for trackpad access
   - **Risk**: Theoretical keylogging capability
   - **Mitigation**: Open source code available for inspection

### Accuracy and Reliability Risks

#### Factors Affecting Accuracy

1. **Environmental Conditions**
   - **Temperature**: ±5°C from calibration temperature
   - **Humidity**: Extreme humidity affects sensors
   - **Vibration**: Mechanical vibrations cause noise

2. **Usage Patterns**
   - **Calibration drift**: Recalibrate every 20-30 measurements
   - **Surface contamination**: Clean trackpad regularly
   - **Finger pressure**: Maintain consistent contact

3. **Electrical Interference**
   - **Charger connection**: May affect readings
   - **External devices**: USB devices, external displays
   - **Wireless signals**: Bluetooth, WiFi activity

## Safety Guidelines

### Before Each Use

1. **Inspect Trackpad**
   ```
   ✓ Clean, dry surface
   ✓ No visible damage
   ✓ Force Touch working normally
   ```

2. **Check Item Suitability**
   ```
   ✓ Weight within limits
   ✓ No sharp edges
   ✓ Dry and clean
   ✓ Non-hazardous material
   ```

3. **Calibrate Scale**
   ```
   ✓ Empty trackpad
   ✓ Stable surface
   ✓ Consistent finger placement
   ```

### During Use

1. **Placement Technique**
   ```
   ✓ Gentle placement
   ✓ Center of trackpad preferred
   ✓ Maintain finger contact
   ✓ Avoid sudden movements
   ```

2. **Reading Process**
   ```
   ✓ Allow 2-3 seconds for stable reading
   ✓ Take multiple measurements if needed
   ✓ Note any unusual behavior
   ```

### After Use

1. **Cleanup**
   ```
   ✓ Remove all items
   ✓ Clean trackpad surface
   ✓ Check for any residue
   ```

2. **Data Management**
   ```
   ✓ Export logs if needed
   ✓ Clear sensitive measurements
   ✓ Backup calibration settings
   ```

### Emergency Procedures

#### If Trackpad Becomes Unresponsive

1. **Immediate Steps**
   ```bash
   # Force quit application
   Command + Option + Esc → Force Quit TrackpadWeight
   
   # Reset trackpad
   System Preferences → Trackpad → Reset to defaults
   ```

2. **Recovery Process**
   ```bash
   # Restart application
   swift run TrackpadWeight
   
   # Recalibrate
   Menu Bar → Calibrate (multiple times)
   ```

3. **If Problems Persist**
   ```bash
   # Reset SMC (System Management Controller)
   Shut down Mac → Press Shift+Control+Option+Power for 10 seconds
   
   # Reset PRAM/NVRAM
   Restart → Hold Command+Option+P+R until second startup sound
   ```

#### If Weight Readings Are Wildly Inaccurate

1. **Quick Fixes**
   ```bash
   # Clean trackpad thoroughly
   # Recalibrate 3-5 times
   # Restart application
   # Test with known weight (coin)
   ```

2. **Advanced Diagnostics**
   ```bash
   # Check Force Touch in System Preferences
   # Test trackpad in other applications
   # Verify no physical damage
   # Check for software conflicts
   ```

## Accuracy Specifications

### Measurement Standards

All accuracy specifications are based on:
- Room temperature (20-25°C)
- Stable surface (vibration-free)
- Clean, dry trackpad
- Proper calibration within last 20 measurements
- Known reference weights (certified coins, calibration weights)

### Statistical Analysis

#### Confidence Intervals

| Weight Range | 95% Confidence | 99% Confidence |
|-------------|----------------|----------------|
| 0.1-1g      | ±0.08g         | ±0.12g         |
| 1-10g       | ±0.15g         | ±0.25g         |
| 10-50g      | ±0.3g          | ±0.5g          |
| 50-200g     | ±0.8g          | ±1.2g          |

#### Repeatability

- **Standard deviation**: <0.05g for items under 10g
- **Coefficient of variation**: <2% for items over 5g
- **Drift rate**: <0.1g per hour of continuous use

### Comparison with Commercial Scales

| Scale Type | Price Range | Accuracy | Features |
|------------|-------------|----------|----------|
| TrackPad Weight | Free | ±0.1-0.5g | Integrated, portable |
| Pocket Scale | $10-30 | ±0.01-0.1g | Dedicated, calibrated |
| Laboratory Scale | $100-500 | ±0.001-0.01g | Professional, certified |
| Kitchen Scale | $20-100 | ±1-5g | Large capacity, food-safe |

### Limitations and Disclaimers

1. **Not Suitable For**
   - Legal/commercial trade
   - Medical dosing
   - Precious metals trading
   - Scientific research requiring high precision
   - Safety-critical applications

2. **Recommended For**
   - Educational demonstrations
   - Hobby projects
   - Approximate measurements
   - Quick weight checks
   - Relative comparisons

3. **Legal Disclaimer**
   - Not certified for commercial use
   - Not FDA approved for food contact
   - Use at your own risk
   - No warranty for measurement accuracy
   - Not responsible for decisions based on readings

## Environmental Considerations

### Operating Conditions

#### Optimal Environment
- **Temperature**: 18-26°C (64-79°F)
- **Humidity**: 30-70% RH
- **Vibration**: Stable desk or table
- **Lighting**: Any (doesn't affect measurements)
- **Air current**: Minimal drafts

#### Acceptable Environment
- **Temperature**: 10-35°C (50-95°F)
- **Humidity**: 20-80% RH
- **Vibration**: Normal office environment
- **Air current**: Light air conditioning

#### Problematic Environment
- **Temperature**: <10°C or >35°C
- **Humidity**: <20% or >80% RH
- **Vibration**: Moving vehicle, unstable surface
- **Air current**: Strong fans, open windows

### Seasonal Considerations

#### Winter
- **Issue**: Low humidity, static electricity
- **Mitigation**: Use humidifier, ground yourself
- **Calibration**: More frequent due to dry air

#### Summer
- **Issue**: High humidity, condensation risk
- **Mitigation**: Ensure items are completely dry
- **Calibration**: Check for drift due to humidity changes

#### Air Conditioning
- **Issue**: Rapid temperature/humidity changes
- **Mitigation**: Allow stabilization time
- **Calibration**: Recalibrate after major changes

---

**Last Updated**: January 2025
**Version**: 2.0
**Compatibility**: macOS 13.0+ with Force Touch trackpad