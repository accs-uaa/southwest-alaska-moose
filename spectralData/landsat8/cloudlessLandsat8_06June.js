/* -*- coding: utf-8 -*-
---------------------------------------------------------------------------
Cloud-reduced Greenest Pixel Composite Landsat 8 Imagery for June 2013-2018
Author: Timm Nawrocki, Alaska Center for Conservation Science
Created on: 2019-03-19
Usage: Must be executed from the Google Earth Engine code editor.
Description: This script produces a cloud-reduced greenest pixel composite (based on maximum NDVI) for bands 1-7 plus Enhanced Vegetation Index-2 (EVI2), Normalized Burn Ratio (NBR), Normalized Difference Moisture Index (NDMI), Normalized Difference Snow Index (NDSI), Normalized Difference Vegetation Index (NDVI), Normalized Difference Water Index (NDWI) using the Landsat8 Top-Of-Atmosphere (TOA) reflectance image collection filtered to the month of June from 2013 through 2018 (inclusive). See Chander et al. 2009 for a description of the TOA reflectance method. The best pixel selection is based on maximum NDVI for all metrics to ensure uniform pixel selection from all bands.
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

// Define a function to create a cloud-reduction mask and calculate NDVI.
var ndviCloudlessAdd = function(image) {
  //Get a cloud score in the range [0, 100].
  var cloudScore = ee.Algorithms.Landsat.simpleCloudScore(image).select('cloud');
  //Create a mask of cloudy pixels from an arbitrary threshold.
  var cloudMask = cloudScore.lte(50);
    //Compute the Normalized Difference Vegetation Index (NDVI).
  var ndviCalc = image.normalizedDifference(['B5', 'B4']).rename('NDVI');
  // Return the masked image with an NDVI band.
  return image.addBands(ndviCalc).updateMask(cloudMask);
};

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
  var nbrCalc = image.normalizedDifference(['B5', 'B7']).rename('NBR');
  // Return the masked image with an NBR band.
  return image.addBands(nbrCalc);
};

// Define a function for NDMI calculation.
var addNDMI = function(image) {
  //Compute the Normalized Difference Moisture Index (NDMI).
  var ndmiCalc = image.normalizedDifference(['B3', 'B5']).rename('NDMI');
  // Return the masked image with an NDMI band.
  return image.addBands(ndmiCalc);
};

// Define a function for NDSI calculation.
var addNDSI = function(image) {
  //Compute the Normalized Difference Snow Index (NDSI).
  var ndsiCalc = image.normalizedDifference(['B3', 'B6']).rename('NDSI');
  // Return the masked image with an NDSI band.
  return image.addBands(ndsiCalc);
};

// Define a function for NDWI calculation.
var addNDWI = function(image) {
  //Compute the Normalized Difference Water Index (NDWI).
  var ndwiCalc = image.normalizedDifference(['B3', 'B5']).rename('NDWI');
  // Return the masked image with an NDWI band.
  return image.addBands(ndwiCalc);
};

// Import Landsat 8 TOA Reflectance (ortho-rectified).
var landsat8TOA = ee.ImageCollection('LANDSAT/LC8_L1T_TOA');

// Filter the image collection by intersection with the area of interest from 2013 to 2018 for the month of June.
var landsatFiltered = landsat8TOA.filterBounds(areaOfInterest).filter(ee.Filter.calendarRange(2013, 2018, 'year')).filter(ee.Filter.calendarRange(6, 6, 'month'));
print('Filtered Collection:', landsatFiltered);

// Calculate NDVI for image collection and add as new band.
var ndviCollection = landsatFiltered.map(ndviCloudlessAdd);

// Make a greenest pixel composite from the image collection.
var compositeGreenest = ndviCollection.qualityMosaic('NDVI');

// Add bands to the greenest pixel composite for EVI-2, NBR, NDMI, NDSI, NDWI.
var compositeGreenest = addEVI2(compositeGreenest);
var compositeGreenest = addNBR(compositeGreenest);
var compositeGreenest = addNDMI(compositeGreenest);
var compositeGreenest = addNDSI(compositeGreenest);
var compositeGreenest = addNDWI(compositeGreenest);
print('Greenest Pixel NDVI:', compositeGreenest)

// Define parameters for NDVI.
var ndviParams = {
  bands: ['NDVI'],
  min: -1,
  max: 1,
  palette: ['blue', 'white', 'green']
};

// Add image to the map.
Map.setCenter(-158.405, 59.682, 5);
var visParams = {bands: ['B4', 'B3', 'B2'], max: 0.3};
Map.addLayer(compositeGreenest, visParams, 'Greenest pixel composite');

// Create a single band image for Landsat 8 bands 1-7 and the additional bands calculated above.
var band_1_ultraBlue = ee.Image(compositeGreenest).select(['B1']);
var band_2_blue = ee.Image(compositeGreenest).select(['B2']);
var band_3_green = ee.Image(compositeGreenest).select(['B3']);
var band_4_red = ee.Image(compositeGreenest).select(['B4']);
var band_5_nearInfrared = ee.Image(compositeGreenest).select(['B5']);
var band_6_shortInfrared1 = ee.Image(compositeGreenest).select(['B6']);
var band_7_shortInfrared2 = ee.Image(compositeGreenest).select(['B7']);
var evi2 = ee.Image(compositeGreenest).select(['EVI2']);
var nbr = ee.Image(compositeGreenest).select(['NBR']);
var ndmi = ee.Image(compositeGreenest).select(['NDMI']);
var ndsi = ee.Image(compositeGreenest).select(['NDSI']);
var ndvi = ee.Image(compositeGreenest).select(['NDVI']);
var ndwi = ee.Image(compositeGreenest).select(['NDWI']);

// Export images to Google Drive.
Export.image.toDrive({
  image: band_1_ultraBlue,
  description: 'Land8_06June_1_ultraBlue',
  scale: 30,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: band_2_blue,
  description: 'Land8_06June_2_blue',
  scale: 30,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: band_3_green,
  description: 'Land8_06June_3_green',
  scale: 30,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: band_4_red,
  description: 'Land8_06June_4_red',
  scale: 30,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: band_5_nearInfrared,
  description: 'Land8_06June_5_nearInfrared',
  scale: 30,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: band_6_shortInfrared1,
  description: 'Land8_06June_6_shortInfrared1',
  scale: 30,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: band_7_shortInfrared2,
  description: 'Land8_06June_7_shortInfrared2',
  scale: 30,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: evi2,
  description: 'Land8_06June_evi2',
  scale: 30,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: nbr,
  description: 'Land8_06June_nbr',
  scale: 30,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: ndmi,
  description: 'Land8_06June_ndmi',
  scale: 30,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: ndsi,
  description: 'Land8_06June_ndsi',
  scale: 30,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: ndvi,
  description: 'Land8_06June_ndvi',
  scale: 30,
  region: areaOfInterest,
  maxPixels: 30000000000
});
Export.image.toDrive({
  image: ndwi,
  description: 'Land8_06June_ndwi',
  scale: 30,
  region: areaOfInterest,
  maxPixels: 30000000000
});