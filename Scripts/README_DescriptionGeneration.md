# Park Description Generation Guide

## Overview
This guide explains how to generate enhanced descriptions for San Francisco parks using the exported data file.

## Files Generated
- `Data/ParksForDescriptionGeneration.json` - Export file with park data for LLM processing
- `Scripts/GenerateParksData.swift` - Updated script that creates both park data and export file

## Park Categories & Counts
- **Destination Parks**: 27 parks (major attractions, 20+ acres typically)
- **Neighborhood Parks**: 86 parks (community hubs, 1-20 acres)
- **Mini Parks**: 81 parks (pocket parks, <1 acre)
- **Plazas**: 24 parks (urban squares and civic spaces)
- **Gardens**: 14 parks (community gardens)

**Total**: 232 parks needing descriptions

## Description Generation Process

### Step 1: Batch Processing Strategy
Process parks in manageable batches to avoid overwhelming the LLM:
- **Batch 1**: Destination parks (27 parks) - Highest priority, most complex
- **Batch 2**: Neighborhood parks (86 parks) - Split into 3-4 sub-batches
- **Batch 3**: Plazas (24 parks) - Single batch
- **Batch 4**: Mini parks (81 parks) - Split into 3-4 sub-batches  
- **Batch 5**: Gardens (14 parks) - Single batch

### Step 2: LLM Prompt Template
```
I have a JSON file with San Francisco park data. Please generate enhanced descriptions for these parks.

For each park, create a detailed, engaging description (2-4 sentences) that includes:
- What makes this park unique or special
- Key features, amenities, or attractions  
- The park's role in its neighborhood/community
- Any historical significance or notable characteristics

Consider the park's category, size (acreage), neighborhood context, and address location.
Focus on what visitors would actually experience and enjoy at each park.

Please return the results in this JSON format:
{
  "parkName": "Enhanced description here...",
  "anotherParkName": "Another enhanced description..."
}

Here are the parks to process:
[paste park data subset here]
```

### Step 3: Quality Guidelines
- **Length**: 2-4 sentences per description
- **Tone**: Informative yet inspiring, encouraging exploration
- **Content**: Focus on visitor experience and unique features
- **Consistency**: Maintain similar style across all descriptions
- **Accuracy**: Use general SF knowledge, avoid making up specific details

### Step 4: Integration
Once all descriptions are generated:
1. Compile results into `Data/ParkDescriptions.json`
2. Update `GenerateParksData.swift` to load and use these descriptions
3. Add fallback to current template-based system for missing parks
4. Regenerate final park data with enhanced descriptions

## Sample Enhanced Description
**Before**: "Alamo Square is an urban plaza that serves as a civic gathering space, hosting community events and providing a central meeting point in the heart of the city."

**After**: "Alamo Square is world-famous for its iconic 'Painted Ladies' Victorian houses and postcard-perfect views of the San Francisco skyline. This hilltop park offers one of the most photographed vistas in the city, with colorful row houses framing downtown's modern towers. The 12.7-acre park provides open space for picnicking while enjoying views that have graced countless movies and television shows."

## Usage
1. Run the generation script: `swift Scripts/GenerateParksData.swift`
2. Use `Data/ParksForDescriptionGeneration.json` for LLM processing
3. Follow the batch processing strategy above
4. Integrate results back into the park generation workflow