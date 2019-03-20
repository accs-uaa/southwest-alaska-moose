/* -*- coding: utf-8 -*-
---------------------------------------------------------------------------
Cloud-reduced Greenest Pixel Composite Sentinel 2 Imagery for May 2016-2018
Author: Timm Nawrocki, Alaska Center for Conservation Science
Created on: 2019-03-19
Usage: Must be executed from the Google Earth Engine code editor.
Description: This script produces a cloud-reduced greenest pixel composite (based on maximum NDVI) for bands 1-12 plus Enhanced Vegetation Index-2 (EVI2), Normalized Burn Ratio (NBR), Normalized Difference Moisture Index (NDMI), Normalized Difference Snow Index (NDSI), Normalized Difference Vegetation Index (NDVI), Normalized Difference Water Index (NDWI) using the Sentinel2 Top-Of-Atmosphere (TOA) reflectance image collection filtered to the month of May from 2016 through 2018. See Chander et al. 2009 for a description of the TOA reflectance method. The best pixel selection is based on maximum NDVI for all metrics to ensure uniform pixel selection from all bands.
- EVI-2 was calculated as (Red - Green) / (Red + [2.4 x Green] + 1), where Red is Landsat 8 Band 4 and Green is Landsat 8 Band 3.
- NBR was calculated as (NIR - SWIR2) / (NIR + SWIR2), where NIR (near infrared) is Landsat 8 Band 5 and SWIR2 (short-wave infrared 2) is Landsat 8 Band 7, using the Google Earth Engine normalized difference algorithm.
- NDMI was calculated as (NIR - SWIR1)/(NIR + SWIR1), where NIR (near infrared) is Landsat 8 Band 5 and SWIR1 (short-wave infrared 1) is Landsat 8 Band 6, using the Google Earth Engine normalized difference algorithm.
- NDSI was calculated as (Green - SWIR1) / (Green + SWIR1), where Green is Landsat 8 Band 3 and SWIR1 (short-wave infrared 1) is Landsat 8 Band 6, using the Google Earth Engine normalized difference algorithm.
- NDVI was calculated as (NIR - Red)/(NIR + Red), where NIR (near infrared) is Landsat 8 Band 5 and Red is Landsat 8 Band 4, using the Google Earth Engine normalized difference algorithm.
- NDWI was calculated as (Green - NIR)/(Green + NIR), where Green is Landsat 8 Band 3 and NIR (near infrared) is Landsat 8 Band 5, using the Google Earth Engine normalized difference algorithm.
---------------------------------------------------------------------------*/

// Define an area of interest geometry.
var areaOfInterest = /* color: #ffc82d */ee.Geometry.Polygon(
        [[[-160.00218, 61.52927],
          [-152.79699, 61.07407],
          [-153.07435, 58.82993],
          [-157.69984, 56.33955],
          [-159.49354, 56.97233],
          [-163.09044, 58.59629],
          [-160.84181, 61.57616]]]);

// Define a function to quality control clouds and cirrus
var maskS2clouds = function(image) {
  var qa_layer = image.select('QA60');
  // Bits 10 and 11 are clouds and cirrus, respectively.
  var cloudBitMask = 1 << 10;
  var cirrusBitMask = 1 << 11;
  // Both flags should be set to zero, indicating clear conditions.
  var mask = qa_layer.bitwiseAnd(cloudBitMask).eq(0)
  .and(qa_layer.bitwiseAnd(cirrusBitMask).eq(0));
  // Return the masked image collection
  return image.updateMask(mask).divide(10000);
}

// Define a function for EVI-2 calculation.
var addEVI2 = function(image) {
  // Assign variables to the red and green Landsat 8 bands.
  var red = image.select('B4');
  var green = image.select('B3');
  //Compute the Enhanced Vegetation Index-2 (EVI2).
  var evi2Calc = red.subtract(green).divide(red.add(green.multiply(2.4)).add(1)).rename('EVI2');
  // Return the masked image with an EVI-2 band.
  return image.addBands(evi2Calc);
};

// Define a function for NDSI calculation.
var addNBR = function(image) {
  //Compute the Normalized Burn Ratio (NBR).
  var nbrCalc = image.normalizedDifference(['B8', 'B12']).rename('NBR');
  // Return the masked image with an NBR band.
  return image.addBands(nbrCalc);
};

// Define a function for NDMI calculation.
var addNDMI = function(image) {
  //Compute the Normalized Difference Moisture Index (NDMI).
  var ndmiCalc = image.normalizedDifference(['B8', 'B11']).rename('NDMI');
  // Return the masked image with an NDMI band.
  return image.addBands(ndmiCalc);
};

// Define a function for NDSI calculation.
var addNDSI = function(image) {
  //Compute the Normalized Difference Snow Index (NDSI).
  var ndsiCalc = image.normalizedDifference(['B3', 'B11']).rename('NDSI');
  // Return the masked image with an NDSI band.
  return image.addBands(ndsiCalc);
};

// Define a function for NDVI calculation.
var addNDVI = function(image) {
  //Compute the Normalized Burn Ratio (NBR).
  var ndviCalc = image.normalizedDifference(['B8', 'B4']).rename('NDVI');
  // Return the masked image with an NBR band.
  return image.addBands(ndviCalc);
};

// Define a function for NDWI calculation.
var addNDWI = function(image) {
  //Compute the Normalized Difference Water Index (NDWI).
  var ndwiCalc = image.normalizedDifference(['B3', 'B8']).rename('NDWI');
  // Return the masked image with an NDWI band.
  return image.addBands(ndwiCalc);
};

// Import Sentinel 2 TOA Reflectance (ortho-rectified).
var sentinel2TOA = ee.ImageCollection("COPERNICUS/S2");

// Filter the image collection by intersection with the area of interest from 2016 to 2018 for the month of May.
var sentinelFiltered = sentinel2TOA.filterBounds(areaOfInterest).filter(ee.Filter.calendarRange(2016, 2018, 'year')).filter(ee.Filter.calendarRange(5, 5, 'month'));
print('Filtered Collection:', sentinelFiltered);

// Create cloud-masked collection
var cloudlessCollection = sentinelFiltered.map(maskS2clouds);

// Add NDVI
var ndviCollection = cloudlessCollection.map(addNDVI);

// Make a greenest pixel composite from the image collection.
var compositeGreenest = ndviCollection.qualityMosaic('NDVI');

// Add bands to the greenest pixel composite for EVI-2, NBR, NDMI, NDSI, NDWI.
var compositeGreenest = addEVI2(compositeGreenest);
var compositeGreenest = addNBR(compositeGreenest);
var compositeGreenest = addNDMI(compositeGreenest);
var compositeGreenest = addNDSI(compositeGreenest);
var compositeGreenest = addNDWI(compositeGreenest);
print('Greenest Pixel NDVI:', compositeGreenest)

// Add image to the map.
Map.setCenter(-158.405, 59.682, 5);
var rgbVis = {
  min: 0.0,
  max: 0.3,
  bands: ['B4', 'B3', 'B2'],
};
Map.addLayer(compositeGreenest, rgbVis, 'Greenest pixel composite');

// Create a single band image for Landsat 8 bands 1-7 and the additional bands calculated above.
var band_1_ultraBlue = ee.Image(compositeGreenest).select(['B1']);
var band_2_blue = ee.Image(compositeGreenest).select(['B2']);
var band_3_green = ee.Image(compositeGreenest).select(['B3']);
var band_4_red = ee.Image(compositeGreenest).select(['B4']);
var band_5_redEdge1 = ee.Image(compositeGreenest).select(['B5']);
var band_6_redEdge2 = ee.Image(compositeGreenest).select(['B6']);
var band_7_redEdge3 = ee.Image(compositeGreenest).select(['B7']);
var band_8_nearInfrared = ee.Image(compositeGreenest).select(['B8']);
var band_8a_redEdge4 = ee.Image(compositeGreenest).select(['B8A']);
var band_11_shortInfrared1 = ee.Image(compositeGreenest).select(['B11']);
var band_12_shortInfrared2 = ee.Image(compositeGreenest).select(['B12']);
var evi2 = ee.Image(compositeGreenest).select(['EVI2']);
var nbr = ee.Image(compositeGreenest).select(['NBR']);
var ndmi = ee.Image(compositeGreenest).select(['NDMI']);
var ndsi = ee.Image(compositeGreenest).select(['NDSI']);
var ndvi = ee.Image(compositeGreenest).select(['NDVI']);
var ndwi = ee.Image(compositeGreenest).select(['NDWI']);

// Export images to Google Drive.
Export.image.toDrive({
  image: band_1_ultraBlue,
  description: 'Sent2_05May_1_ultraBlue',
  scale: 60,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: band_2_blue,
  description: 'Sent2_05May_2_blue',
  scale: 10,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: band_3_green,
  description: 'Sent2_05May_3_green',
  scale: 10,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: band_4_red,
  description: 'Sent2_05May_4_red',
  scale: 10,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: band_5_redEdge1,
  description: 'Sent2_05May_5_redEdge1',
  scale: 20,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: band_6_redEdge2,
  description: 'Sent2_05May_6_redEdge2',
  scale: 20,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: band_7_redEdge3,
  description: 'Sent2_05May_7_redEdge3',
  scale: 20,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: band_8_nearInfrared,
  description: 'Sent2_05May_8_nearInfrared',
  scale: 10,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: band_8a_redEdge4,
  description: 'Sent2_05May_8a_redEdge4',
  scale: 20,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: band_11_shortInfrared1,
  description: 'Sent2_05May_11_shortInfrared1',
  scale: 20,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: band_12_shortInfrared2,
  description: 'Sent2_05May_12_shortInfrared2',
  scale: 20,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: evi2,
  description: 'Sent2_05May_evi2',
  scale: 10,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: nbr,
  description: 'Sent2_05May_nbr',
  scale: 20,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: ndmi,
  description: 'Sent2_05May_ndmi',
  scale: 20,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: ndsi,
  description: 'Sent2_05May_ndsi',
  scale: 20,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: ndvi,
  description: 'Sent2_05May_ndvi',
  scale: 10,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: ndwi,
  description: 'Sent2_05May_ndwi',
  scale: 10,
  region: areaOfInterest,
  maxPixels: 30000000000
});