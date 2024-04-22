#include "pch.h"
#include <cstring> 
#define LaplaceFunction __declspec(dllexport)

extern "C" {


    LaplaceFunction void FiltrImage(unsigned char* ImageArray, int size, int width, int height, int bytesPerPixel, int start, unsigned char* resultArray) {
        int LaplaceMask[9] = { 0, -1, 0, -1, 4, -1, 0, -1, 0 };
        //int* resultArray = new int[size];

        for (int i = 1; i < height-1; i++) {
            for (int j = 4; j < width-4; j+=4) {
                int sumR = 0;
                int sumG = 0;
                int sumB = 0;
                int maskIt = 0;
                int pixelIndex = i * width + j;
                for (int x = -1; x <= 1; x++) {
                    for (int y = -1; y <= 1; y += 1) {
                        int currentPixel = (i + x) * width + (j + y * 4)+start;
                        sumR += static_cast<int>(ImageArray[currentPixel]) * LaplaceMask[maskIt];  
                        sumG += static_cast<int>(ImageArray[currentPixel+1]) * LaplaceMask[maskIt];
                        sumB += static_cast<int>(ImageArray[currentPixel+2]) * LaplaceMask[maskIt];

                        maskIt++;
                    }
                }
                if (sumR < 0) sumR = 0;
                if (sumG < 0) sumG = 0;
                if (sumB < 0) sumB = 0;

                if (sumR > 255) sumR = 255;
                if (sumG > 255) sumG = 255;
                if (sumB > 255) sumB = 255;

                pixelIndex += start;
                resultArray[pixelIndex] = static_cast<unsigned char>(sumR);
                resultArray[pixelIndex+1] = static_cast<unsigned char>(sumG);
                resultArray[pixelIndex+2] = static_cast<unsigned char>(sumB);
                resultArray[pixelIndex+3] = static_cast<unsigned char>(255);
            }
        }
       
    }
}
