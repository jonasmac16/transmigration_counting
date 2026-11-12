// =========================================================================
// 1. RESOLVE PATHS RELATIVE TO THIS MACRO FILE & SET PARAMETERS
// =========================================================================
macroPath = getInfo("macro.filepath");
if (macroPath == "") {
    exit("Error: Please save this macro as a .ijm file on disk before running it.");
}

scriptDir  = File.getParent(macroPath);
projectDir = File.getParent(scriptDir) + File.separator;
inputDir   = "/home/jonas/projects/05_Tcell_transmigration/data/01_pilot/"; //projectDir + "data/01_pilot/";
outputDir  = "/home/jonas/projects/05_Tcell_transmigration/output/01_pilot/"; //projectDir + "output/01_pilot/"

sigmaVal      = 1.5;        // Gaussian Blur radius (pixels)
rollingBall   = 20;         // Background subtraction radius (larger than widest dot)
localRadius   = 15;         // Radius (pixels) for local thresholding window
localContrast = 15;         // Bernsen contrast cutoff (raise to 25-40 to ignore dim noise)
minSize       = 10;         // Minimum dot area in pixels (raise to filter out small specks)
maxSize       = "Infinity"; // Maximum dot area in pixels
minCirc       = 0.55;       // Circularity: 1.00 = perfect circle; 0.55 allows leeway
minBrightness = 10;          // Minimum Mean pixel intensity on Raw_Image (e.g. set to 500 or 1000)
outlinePx     = 2;          // Line thickness (pixels) for verification outlines
// =========================================================================

if (!File.exists(outputDir)) File.makeDirectory(outputDir);

verifyDir = outputDir + "Verification_Images/";
if (!File.exists(verifyDir)) File.makeDirectory(verifyDir);

roiDir = outputDir + "Saved_ROIs/";
if (!File.exists(roiDir)) File.makeDirectory(roiDir);

setBatchMode(true);
list = getFileList(inputDir);

if (list.length == 0) {
    exit("No files found in: " + inputDir);
}

run("Clear Results");
if (roiManager("count") > 0) roiManager("Delete");

run("Set Measurements...", "area mean max shape redirect=None decimal=2");

summaryTable = "Summary_Counts";
Table.create(summaryTable);
summaryRow = 0;

for (i = 0; i < list.length; i++) {
    if (endsWith(list[i], ".tif") || endsWith(list[i], ".tiff") || endsWith(list[i], ".png") || endsWith(list[i], ".jpg")) {
        
        open(inputDir + list[i]);
        title = getTitle();
        baseName = File.nameWithoutExtension;
        
        getMinAndMax(origMin, origMax);
        
        // 2. Keep native bit-depth unless image is 24-bit RGB colour
        if (bitDepth() == 24) {
            run("8-bit");
        }
        rename("Raw_Image");
        run("Duplicate...", "title=Mask_Image");
        
        // 3. Smooth noise & flatten background
        run("Gaussian Blur...", "sigma=" + sigmaVal);
        run("Subtract Background...", "rolling=" + rollingBall);
        
        // 4. Bernsen Local Threshold ignores low-contrast dark background regions
        run("8-bit");
        run("Auto Local Threshold", "method=Bernsen radius=" + localRadius + " parameter_1=" + localContrast + " parameter_2=0 white");
        
        // 5. Filter by Size AND Circularity, storing candidates in ROI Manager
        run("Analyze Particles...", "size=" + minSize + "-" + maxSize + " circularity=" + minCirc + "-1.00 show=Nothing add");
        
        // 6. Filter out dim false positives based on Raw_Image brightness
        selectWindow("Raw_Image");
        totalCandidates = roiManager("count");
        
        if (totalCandidates > 0 && minBrightness > 0) {
            for (k = totalCandidates - 1; k >= 0; k--) {
                roiManager("select", k);
                getStatistics(area, mean);
                if (mean < minBrightness) {
                    roiManager("delete");
                }
            }
        }
        
        // CRITICAL FIX: Clear any active ROI selection so Duplicate copies the WHOLE image
        run("Select None");
        
        startRow = nResults;
        dotCount = roiManager("count");
        
        // 7. Measure accepted dots, save ROIs, and create full-size Verification Image
        if (dotCount > 0) {
            roiManager("Save", roiDir + baseName + "_RoiSet.zip");
            
            roiManager("Measure");
            endRow = nResults;
            
            for (r = startRow; r < endRow; r++) {
                setResult("Image_Name", r, title);
                setResult("Dot_ID", r, (r - startRow) + 1);
            }
            
            selectWindow("Raw_Image");
            run("Select None");
            run("Duplicate...", "title=Verify");
            setMinAndMax(origMin, origMax);
            run("RGB Color");
            setForegroundColor(255, 255, 0);
            setLineWidth(outlinePx);
            
            for (j = 0; j < dotCount; j++) {
                roiManager("select", j);
                run("Draw");
            }
            run("Select None");
            
            saveAs("Tiff", verifyDir + baseName + "_verified.tif");
            roiManager("Delete");
        } else {
            selectWindow("Raw_Image");
            run("Select None");
            run("Duplicate...", "title=Verify");
            setMinAndMax(origMin, origMax);
            run("RGB Color");
            saveAs("Tiff", verifyDir + baseName + "_verified.tif");
        }
        
        close("Verify");
        close("Mask_Image");
        close("Raw_Image");
        
        // 8. Log total count into Summary table
        Table.set("Image_Name", summaryRow, title, summaryTable);
        Table.set("Total_Dot_Count", summaryRow, dotCount, summaryTable);
        summaryRow++;
    }
}

updateResults();
saveAs("Results", outputDir + "Individual_Dot_Measurements.csv");
Table.save(outputDir + "Total_Counts_Summary.csv", summaryTable);

setBatchMode(false);
print("Done! Processed " + summaryRow + " images.");


