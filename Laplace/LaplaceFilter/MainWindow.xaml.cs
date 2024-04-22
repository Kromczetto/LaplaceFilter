using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Media.Media3D;
using System.Windows.Threading;
using System.Windows.Controls;
using System.Diagnostics;
using System.Threading;
using System.Windows.Ink;
using System.Security.Permissions;
using System.Windows.Markup;
using System.ComponentModel;
using System.Reflection;
using System.Linq;

/*
 * POMYSLY 
 * -narzie zmienic tak zeby asm sie dodawal ten offset i zobaczymy co sie stanie 
 */
namespace LaplaceFilter
{
 
    public partial class MainWindow : Window
    {
        public CroppedBitmap finalBitmap;
        public List<byte> processedImage;
        public int imageWidth;
        public int imageHeight;
        private List<WriteableBitmap> processedImages = new List<WriteableBitmap>();

        private BitmapImage sourceImage;
        private int parts;
        private string selectedFilePath;
        private Thread[] ThreadsData;
        private byte[] finalImage;
        public WriteableBitmap resultBitmap;
        public Int32Rect rect;
        private static int counter;

        public byte[] imageBytes;
        private int offset = 0;

        [DllImport("D:\\wazne rzeczy 04.03.2024\\LaplaceFilter\\x64\\Debug\\laplaceCpp.dll", CallingConvention = CallingConvention.Cdecl)]
        public static extern void FiltrImage(IntPtr arrayPtr, int size, int width, int height, int bytesPerPixel,int start, IntPtr resultArray);

        [DllImport("D:\\wazne rzeczy 04.03.2024\\LaplaceFilter\\x64\\Debug\\LaplaceAsm.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern void LaplaceApply(IntPtr arrayPtr, int width, int height, IntPtr resultArray,int shift);
        public MainWindow()
        {
            InitializeComponent();

        }
        private void SelectFile_Click(object sender, RoutedEventArgs e)
        {
            OpenFileDialog openFileDialog = new OpenFileDialog
            {
                Title = "Wybierz plik graficzny",
                Filter = "Pliki graficzne (*.png, *.jpg)|*.png;*.jpg",
            };

            if (openFileDialog.ShowDialog() == true)
            {
                selectedFilePath = openFileDialog.FileName;

                sourceImage = new BitmapImage(new Uri(selectedFilePath));
                EntryImage.Source = sourceImage;

                filtr.IsEnabled = true;
                ExecutingTime.Content = "Czas wykonywania algorytmu: ";
            }
        }

        private void Filtr_Click(object sender, RoutedEventArgs e)
        {
            

            parts = (int)MySlider.Value;

            ThreadsData = new Thread[parts];
            splitData(sourceImage, parts);
            counter = 0;
            filtr.IsEnabled = false;
        }
        private void splitData(BitmapImage sourceImage, int parts)
        {
            int sourceWidth = (int)sourceImage.PixelWidth;
            int sourceHeight = (int)sourceImage.PixelHeight;
            int partHeight = sourceHeight / parts;
            imageHeight = sourceHeight;
            imageWidth = sourceWidth;

            

            byte[] bitmapData = new byte[sourceHeight * sourceWidth * 4];

            byte[] AsmResult = new byte[sourceHeight * sourceWidth * 4];
            IntPtr AsmResultPtr = Marshal.UnsafeAddrOfPinnedArrayElement(AsmResult, 0);

            CroppedBitmap croppedBitmap = new CroppedBitmap(sourceImage, new Int32Rect(0, 0, sourceWidth, sourceHeight));
            int stride = croppedBitmap.PixelWidth * 4; // 4 bajty na piksel (RGBA)


            croppedBitmap.CopyPixels(bitmapData, stride, 0);
            IntPtr bitmapDataPtr = Marshal.UnsafeAddrOfPinnedArrayElement(bitmapData, 0);

            int[] partsArray = new int[parts];

            for (int i = 0; i < parts; i++)
            {
                if (i == parts - 1)
                {
                    partsArray[i] = sourceHeight - (i * (int)(sourceHeight / parts));
                }
                else
                {
                    partsArray[i] = (int)(sourceHeight / parts);
                }

            }

            int startY = 0;
            
            for (int i = 0; i < parts; i++)
            {
                int tempPartHeight = partsArray[i];
                if (parts == 1)
                {
                    tempPartHeight = partsArray[i];
                }
                if (i == 0)
                {
                    startY = 0;
                }
                else if (i == parts - 1)
                {
                    startY = sourceHeight - tempPartHeight;
                    
                }
                else
                {
                    startY += partsArray[i];
                }
                int o = startY * imageWidth * 4 ;
             
                int index = i;
                if (CPlusPlusRadioButton.IsChecked == true)
                {
                    ThreadsData[index] = new Thread(() => ProcessImagesLaPlaceCpp(bitmapDataPtr, sourceWidth, tempPartHeight, o, AsmResultPtr, i, parts));
                }

                else if (ASMRadioButton.IsChecked == true)
                {
                    ThreadsData[index] = new Thread(() => ProcessImagesLaPlace(bitmapDataPtr, sourceWidth, tempPartHeight, o, AsmResultPtr, i, parts));
                }
                else
                {
                    if (i == 0)
                    {
                        MessageBox.Show("Wybierz filtr");
                    }
                    ThreadsData[index] = new Thread(() => Thread.Sleep(1));


                }
                    int a = 1;
            }
            
            for (int i = 0; i < parts; i++)
            {

                int index = i;
                ThreadsData[index].Start();
            }

            Stopwatch stopwatch = new Stopwatch();
            stopwatch.Start();
            for (int i = 0; i < parts; i++)
            {
                int index = i;
                ThreadsData[index].Join();
                
            }
            stopwatch.Stop();
            long elapsedTicks = stopwatch.ElapsedTicks;
            double elapsedMilliseconds = stopwatch.ElapsedMilliseconds;
            TimeSpan elapsed = stopwatch.Elapsed;
            ExecutingTime.Content = $"Czas wykonywania algorytmu: {elapsedTicks} ";
            
        }
        private readonly object lockObject = new object();

        private void ProcessImagesLaPlace(IntPtr bitmapDataPtr, int width, int height, int startY, IntPtr AsmResultPtr, int i, int parts)
        {
            if (width > 0 && height > 0)
            {
                // int stride = width * 4;
                lock (lockObject)
                {
                    Dispatcher.InvokeAsync(() =>
                    {
                        height--;
                        counter++;
                        LaplaceApply(bitmapDataPtr, width * 4, height, AsmResultPtr, startY);
                        if (counter == parts)
                        {
                            DisplayLastProcessedImage(AsmResultPtr);
                        }
                        filtr.IsEnabled = true;
                    }, DispatcherPriority.Background);
                }
            }
            else
            {
                Dispatcher.Invoke(() =>
                {
                    MessageBox.Show("Obrazek jest pusty.");
                });
            }
        }

        private void ProcessImagesLaPlaceCpp(IntPtr bitmapDataPtr, int width, int height, int startY, IntPtr AsmResultPtr, int i, int parts)
        {
            if (width > 0 && height > 0)
            {
                // int stride = width * 4;
                Dispatcher.InvokeAsync(() =>
                {
                    counter++;
                    FiltrImage(bitmapDataPtr, width * height, width * 4, height, 3, startY, AsmResultPtr);
                    if (counter == parts)
                    {
                        DisplayLastProcessedImage(AsmResultPtr);
                    }
                    filtr.IsEnabled = true;
                }, DispatcherPriority.Background);
            }
            else
            {
                Dispatcher.Invoke(() =>
                {
                    MessageBox.Show("Obrazek jest pusty.");
                });
            }
        }

        private void DisplayLastProcessedImage(IntPtr imageBytesPtr)
        {
            
                resultBitmap = new WriteableBitmap(imageWidth, imageHeight, 96, 96, PixelFormats.Bgr32, null);
                rect = new Int32Rect(0, 0, imageWidth, imageHeight);

                imageBytes = new byte[imageWidth * imageHeight * 4];
                Marshal.Copy(imageBytesPtr, imageBytes, 0, imageWidth * imageHeight * 4);

                resultBitmap.WritePixels(rect, imageBytes, imageWidth * 4, 0);

                FinalImage.Source = resultBitmap;
            
        }


    }

}
