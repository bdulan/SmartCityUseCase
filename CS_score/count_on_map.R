library(leaflet)
library("data.table")
library("sp")
library("shiny")
library('shinydashboard')

ui <- fluidPage(
  titlePanel("EV Charging Station Location Score!"),
  sidebarLayout(
    # Sidebar with a slider input
    sidebarPanel(
      sliderInput("Bin size",
                  "Number of bins:",
                  min = 0,
                  max = 300,
                  value = 256)
    ),
   mainPanel(
    leafletOutput("mymap"))))

#read data
cnt_dat <- read.table("area_count_16x16.txt", header=F)
loc_dat <- read.table("EV_station_locations.txt", header=F)
## Gas Station locations
gsl_dat <- read.table("gas_station_locations.txt", header=F)

minlat <- 42.20 # selected by hit and trial
minlong <- -83.83

gridspacing_lat <- (0.0375/4.0) # this spacing was pre-calculated, hardcoded for now
gridspacing_long <- (0.05/4.0)

ngrid <- 16 # for a 16x16 grid system
lat1_list <- c()
lat2_list <- c()
long1_list <- c()
long2_list <- c()

l <- c(1:ngrid)
iset <- expand.grid(l,l)
#creating co-ordinates of the rectangles for each grid
for (i in 1:length(iset[,1])) 
{ lat1_list  <- c(lat1_list,  minlat + (iset[i,2]-1)*gridspacing_lat)
  lat2_list  <- c(lat2_list,  minlat + iset[i,2]*gridspacing_lat)
  long1_list <- c(long1_list, minlong + (iset[i,1]-1)*gridspacing_long)
  long2_list <- c(long2_list, minlong + iset[i,1]*gridspacing_long)
}


server <- function(input, output, session) {
  
  output$mymap <- renderLeaflet({leaflet() %>%
    setView(lng = -83.7483, lat = 42.2814, zoom = 12) %>%
    addTiles(group = "Open Street Map") %>%
    addProviderTiles("MapQuestOpen.Aerial", group = "Map Quest Open Aerial") %>%
    addProviderTiles("Thunderforest.Transport", group = "Thunderforest Transport") %>%
    addProviderTiles("OpenMapSurfer.Roads", group = "Open Map Surfer Roads") %>%
    #addTiles(data = df[100:110,], lat = ~ lat, lng = ~ long)%>%
    addLayersControl(
      baseGroups = c("Open Street Map", "Map Quest Open Aerial",
                     "Thunderforest Transport", "Open Map Surfer Roads")) %>% 
      #fillOpacity sets color intensity according to vehicle density
      addRectangles(lng1=long1_list, lat1=lat1_list,
                    lng2=long2_list, lat2=lat2_list,
                    fillColor = 'darkorange', fillOpacity = 2.0*cnt_dat[,1]/max(cnt_dat), weight = 0.2) %>%
      addCircleMarkers(lng=loc_dat[,2], lat=loc_dat[,1], radius = 6, color = "blue", weight=0.2, fillOpacity = 0.4)
    })
}

shinyApp(ui,server)