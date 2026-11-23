###################################################################################### SHINY SERVER UI #####

# Shared GESIS styling for the authenticated app and the login screen.
gesis_page_styles <- tagList(
  tags$link(rel = "stylesheet", href = "package/dist/gesis-web.css"),
  tags$style(HTML("
    .page-banner.microsite {
      background: url('banner-microsite-07.svg') center/cover no-repeat;
      min-height: 180px;
      margin-bottom: 0 !important;
    }
    .page-banner.microsite .page-banner--inner {
      background: transparent !important;
      min-height: inherit;
      overflow-wrap: anywhere;
    }

    footer.page-footer {
      position: static;
      clear: both;
      overflow-wrap: anywhere;
    }
    footer.page-footer .page-footer--inner > * {
      min-width: 0;
    }
    footer.page-footer .social-media-icons,
    footer.page-footer nav.footer {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: .25rem .5rem;
    }
    footer.page-footer .leibniz-logo-wrapper img {
      height: auto;
    }
  "))
)

gesis_footer <- includeHTML("www/gesis-footer.html")

# Define UI for ChatDashboard application
app_ui <- fluidPage(theme = shinytheme("flatly"),
                    
                    # Detecting browser for mobile optimization
                    shinybrowser::detect(),
                    
                    # keep session alive for locked phones
                    tags$head(tags$script(HTML("
                        setInterval(function(){
                          Shiny.setInputValue('keepalive', Date.now(), {priority:'event'});
                        }, 15000);
                      "))),
                    
                    # ensure users start at the top of a new page when changing tabs on mobile
                    tags$head(tags$script(HTML("
                      (function(){
                        function scrollTopNow(){
                          window.scrollTo(0,0);
                          document.body.scrollTop = 0;
                          document.documentElement.scrollTop = 0;
                          setTimeout(function(){ window.scrollTo(0,0); }, 0); // iOS
                        }
                        // Bootstrap tab change (navbarPage)
                        $(document).on('shown.bs.tab', 'a[data-toggle=\"tab\"]', scrollTopNow);
                        // Your custom microsite nav
                        $(document).on('click', '.gs-micro-nav a', function(){ setTimeout(scrollTopNow, 0); });
                        // After you rewire visible/active tabs
                        Shiny.addCustomMessageHandler('microNavVisible', function(){ setTimeout(scrollTopNow, 0); });
                      })();
                    "))),
                    
                    # website zoom
                    tags$head(tags$style(HTML("
                    /* Shinywaiter immer bildschirmfüllend, in allen Browsern */
                    .waiter-overlay, #waiter-overlay, .waiter {
                      position: fixed !important;
                      top: 0 !important; right: 0 !important; bottom: 0 !important; left: 0 !important;
                      width: 100vw !important;
                      height: 100vh !important;
                      max-width: 100vw !important;
                      max-height: 100vh !important;
                      transform: none !important;
                      -webkit-transform: none !important;
                      -ms-transform: none !important;
                      -moz-transform: none !important;
                      z-index: 2147483647 !important;
                    }
                  
                    /* Moderne Browser: exakte Viewport-Höhe */
                    @supports (height: 100dvh) {
                      .waiter-overlay, #waiter-overlay, .waiter { height: 100dvh !important; }
                    }
                  "))),
                                        
                    ##################################### UI SETUP ####
                    
                    # Shiny helpers
                    useShinyjs(),
                    setBackgroundColor("#ffffff"),
                    useWaiter(),
                    
                    tags$head(
                      gesis_page_styles,
                      tags$style(HTML("
                    /* ---------- FILE INPUT (Bootstrap 3) ---------- */
                    .bs3-fileinput .input-group { display: table !important; width: 100% !important; border-collapse: separate; }
                    .bs3-fileinput .input-group .form-control { display: table-cell !important; width: 100% !important; float: none; }
                    .bs3-fileinput .input-group-btn,
                    .bs3-fileinput .input-group-prepend,
                    .bs3-fileinput .input-group-append,
                    .bs3-fileinput label.input-group-btn { display: table-cell !important; width: 1%; white-space: nowrap; vertical-align: middle; }
              
                    .btn-file { position: relative; overflow: hidden; }
                    .btn-file > input[type=file]{
                      position:absolute !important; top:0; right:0; min-width:100%; min-height:100%;
                      font-size:100px; text-align:right; opacity:0; cursor:inherit; display:block;
                    }
              
                    /* Make the 'Datei auswählen' clearly a button */
                    .bs3-fileinput .btn-file{
                      display:inline-block; background-color:#1E8CC8 !important; color:#fff !important;
                      border:none !important; padding:6px 16px !important; font-weight:600 !important;
                      border-radius:0 6px 6px 0 !important;
                    }
                    .bs3-fileinput .btn-file:hover{ background-color:#166b97 !important; }
                    .bs3-fileinput .input-group .form-control{
                      background:#fff; border:1px solid #cbd5e1; box-shadow:none; height:36px; line-height:1.4;
                      border-radius:6px 0 0 6px !important;
                    }
                    .bs3-fileinput input[type=file]{ all: unset; }
                    .bs3-fileinput input[type=file]::file-selector-button{ display:none !important; }
              
                    /* ShinyAlerts: prevent stray text input */
                    .swal2-popup .swal2-input{display:none!important;}
              
                    .tab-content { padding-bottom: 3rem; }
                    .dataTables_length select { display: inline-block; }

                    /* ---------- MICROSITE NAV (full width, dark, GESIS colors) ---------- */
                    .gs-micro-nav.has-bg-color{
                      background-color: var(--gs-darkblue-100,#072f57) !important;
                      color:#fff; margin:0; padding:.5rem 1rem; border-radius:0 0 12px 12px;
                    }
                    .gs-micro-nav a{
                      color:#fff; display:inline-block; padding:.4rem .8rem; border-radius:999px; text-decoration:none;
                      border:1px solid transparent;
                    }
                    .gs-micro-nav a:hover, .gs-micro-nav a:focus{
                      background:rgba(22,107,151,.15); color:#fff;
                    }
                    .gs-micro-nav a.is-active,
                    .gs-micro-nav a[aria-current='page'],
                    .gs-micro-nav a.active{
                      background: var(--gs-darkblue-80,#166b97); color:#fff; border-color: var(--gs-darkblue-80,#166b97);
                    }
                    
                          /* Hide Bootstrap navbar strip; we use microsite nav for tabs */
                          .navbar, .navbar .navbar-header, .navbar .navbar-nav{display:none!important; height:0; min-height:0; margin:0; padding:0; border:0;}
                        "))
                    ),
                    
                    # GESIS micro header and banner
                    tags$div(id = "gesis-micro-header", includeHTML("www/gesis-micro-header.html")),
                    includeHTML("www/gesis-microsite-banner.html"),
                    
                    # GESIS microsite navigation controlling Shiny tabs (full width, dark)
                    tags$nav(class = "gs-micro-nav container-fluid has-bg-color gs-darkblue--65",
                             tags$ul(class = "list-inline",
                                     tags$li(tags$a(href = "#", `data-tab` = display_text[3],  display_text[3]  )), # Überblick
                                     tags$li(tags$a(href = "#", `data-tab` = display_text[15], display_text[15] )), # Daten hochladen
                                     tags$li(tags$a(href = "#", `data-tab` = display_text[87], display_text[87] )), # Spender Auswahl
                                     tags$li(tags$a(href = "#", `data-tab` = display_text[28], display_text[28] )), # Daten auswählen
                                     tags$li(tags$a(href = "#", `data-tab` = display_text[46], display_text[46] )), # Ergebnisse
                                     tags$li(tags$a(href = "#", `data-tab` = display_text[76], display_text[76] ))  # Impressum
                             )
                    ),
                    
                    # Click handler + active state
                    tags$script(HTML("
                    $(document).on('click','.gs-micro-nav a',function(e){
                      e.preventDefault();
                      $('.gs-micro-nav a').removeClass('is-active');
                      $(this).addClass('is-active');
                      Shiny.setInputValue('go_tab', $(this).data('tab'), {priority:'event'});
                    });
                  ")),
                    
                    tags$script(HTML("
                      Shiny.addCustomMessageHandler('microNavVisible', function(msg){
                        var show = msg.show || [];
                        var active = msg.active || null;
                        $('.gs-micro-nav a').each(function(){
                          var $a = $(this), tab = $a.data('tab');
                          if (show.indexOf(tab) !== -1) { $a.closest('li').show(); }
                          else { $a.closest('li').hide(); }
                          $a.toggleClass('is-active', !!active && tab === active);
                        });
                      });
                    ")),
                    
                    # fix sweet alerts for GESIS CSS
                    tags$head(tags$script(HTML("
                  new MutationObserver(function(){
                    var p=document.querySelector('.swal2-popup');
                    if(!p) return;
                    p.querySelectorAll('.swal2-input,.swal2-textarea,.swal2-select,.swal2-radio,.swal2-checkbox')
                     .forEach(function(e){ e.style.display='none'; e.style.height='0'; e.style.padding='0'; e.style.border='0'; });
                  }).observe(document.body,{childList:true,subtree:true});
                "))),
                    
                    
                    
                    
                    ##################################### MAIN UI ####
                    
                    # Logo and App name in navbar page
                    navbarPage(title = tags$img(height = 35,
                                                width = 35,
                                                src = "WhatsR_logo.png"),
                               id = "ChatDashboard",
                               windowTitle = "ChatDashboard",
                               
                               ##################################### Overview Page ####
                               tabPanel(display_text[3],
                                        
                                        # whole page
                                        fluidRow(
                                          
                                          # Heading 1
                                          column(tags$p(style = "text-align: justify;",
                                                        HTML(display_text[4])),
                                                 HTML("<br>"),
                                                 HTML(display_text[5]),
                                                 HTML("<br><br>"),
                                                 HTML(display_text[6]),
                                                 HTML("<br><br>"),
                                                 HTML(display_text[7]),
                                                 HTML("<br>"),
                                              
                                          
                                          # Heading 2
                                          #column(tags$p(style = "text-align: justify;",
                                          #              HTML(display_text[8]),
                                          #              HTML(display_text[9]),
                                          #              HTML("<br><br>")
                                          #),
                                          #width = 6, offset = 3),
                                          
                                          # Heading 3
                                          #column(tags$p(style = "text-align: justify;",
                                          #              HTML(display_text[10]),
                                          #              HTML(display_text[11]),
                                          #              HTML("<br><br>")
                                          #),
                                          #width = 6, offset = 3),
                                          
                                          # Heading 4
                                          #column(tags$p(style = "text-align: justify;",
                                          #              HTML(display_text[12]),
                                          #              HTML(display_text[13]),
                                          #              HTML("<br><br>")
                                          #),
                                          #width = 6, offset = 3),
                                          
                                          tags$head(
                                            tags$style(HTML("
                                                      .callout{padding:1rem;border-left:4px solid #0d6efd;background:#f8f9fa;border-radius:.25rem}
                                                      .callout h4{margin-top:0;margin-bottom:.5rem}
                                                    "))
                                          ),
                                          tags$div(class = "callout",
                                                   tags$h4("Wichtig:"),
                                                   "Diese Website ist für den PC optimiert. Sie können mit dem Smartphone fortfahren, sollten aber vermeiden den Tab zu schließen, zu minimieren oder das Display zu sperren bevor die Datenspende abgeschlossen ist um Verbindungsprobleme zu vermeiden."
                                          ),
                                          
                                          HTML("<br><br>"), width = 6, offset = 3),
                                          
                                          # Consent button
                                          column(12, align = "center",
                                                 actionButton("IntroCheck",
                                                              label = display_text[14],
                                                              class = "btn-warning",
                                                              style = "color: #FFFFFF; background-color: #E2007A; border-color: #E2007A"),
                                                 HTML("<br><br><br><br><br><br>")
                                          )
                                          
                                          # End of fluidRow
                                        )
                                        
                                        # End of tabPanel
                               ),
                               
                               ##################################### DATA UPLOAD PAGE ####
                               tabPanel(display_text[15],
                                        
                                        # Sidebar
                                        sidebarLayout(
                                          sidebarPanel(h2(display_text[16],
                                                          align = "center"),
                                                       
                                                       # Text for sidebar panel
                                                       helpText(display_text[18]),
                                                       helpText(display_text[19]),
                                                       
                                                       # File selection field
                                                       div(class = "bs3-fileinput",
                                                           fileInput("file", label = "",
                                                                     accept = c(".txt", ".zip"),
                                                                     buttonLabel = display_text[20])
                                                       ),
                                                       
                                                       # Upload button
                                                       actionButton(inputId = "submit",
                                                                    label = display_text[21],
                                                                    class = "btn-warning",
                                                                    style = "color: #FFFFFF; background-color: #E2007A; border-color: #E2007A")
                                          ),
                                          
                                         
                                          #### MAIN PANEL 
                                          mainPanel(
                                            column(
                                              width = 10, offset = 1,
                                              
                                              # Heading + body text
                                              tags$h2("WhatsApp Chatverläufe exportieren"),
                                              tags$p("Wenn Sie den Chatverlauf bereits auf ihr Telefon oder Ihren PC exportiert haben können Sie diesen direkt links (PC) oder oben (Smartphone) hochladen. Falls nicht, klicken Sie hier auf den entsprechenden Reiter unten um die richtige Anleitung zum Export von WhatsApp Chatverläufen für Ihr Telefon auszuwählen."),
                                              
                                              # minimal spacing
                                              tags$head(
                                                tags$style(HTML("
                                                  details { margin-bottom: 16px; }
                                                  summary { cursor: pointer; font-weight: 600; padding: 8px 0; }
                                                  details > *:not(summary) { margin-top: 8px; }
                                                  img { display:block; }
                                                "))
                                              ),
                                              
                                              # ANDROID
                                              tags$details(
                                                tags$summary("Android"),
                                                tags$ul(
                                                  tags$li("Öffnen Sie WhatsApp auf Ihrem Smartphone und klicken Sie auf den Chat, dessen Verlauf Sie bereitstellen möchten."),
                                                  tags$li("Klicken Sie oben rechts im Chat auf die drei vertikalen Punkte."),
                                                  tags$li("Wählen Sie die Option `Mehr` im folgenden Menü aus."),
                                                  tags$li("Klicken Sie auf die Option `Chat exportieren`."),
                                                  tags$li("Im folgenden Fenster wählen Sie die Option `Ohne Medien` aus, falls eine Auswahl angezeigt wird."),
                                                  tags$li("Wählen Sie nun ein E-mail Programm aus der Liste aus. Es öffnet sich eine E-mail an welche der Chatverlauf automatisch angehängt ist."),
                                                  tags$li("Geben Sie in das Feld 'An' Ihre eigene E-mail Adresse ein und senden Sie die E-mail an sich selbst ab.")
                                                ),
                                                tags$img(src = "DataExport_Guide_Android.png",
                                                         style = "width:100%;height:auto;", alt = "Android export guide"),
                                                tags$ul(
                                                  tags$li("Öffnen Sie das E-mail Postfach an welches Sie den Chatverlauf gerade geschickt haben."),
                                                  tags$li("Laden Sie den Anhang der E-mail herunter. Dies kann entweder eine .zip Datei oder eine .txt Datei sein."),
                                                  tags$li("Laden Sie den heruntergeladenen Chatverlauf im Fenster links (PC), bzw. oben (Smartphone,) auf diese Website hoch."),
                                                  tags$li("Auf der nächsten Seite erhalten Sie die Möglichkeit Ihren anonymisierten Chatverlauf nochmal einzusehen und anschließend abzuschicken.")
                                                )
                                              ),
                                              
                                              # iPHONE
                                              tags$details(
                                                tags$summary("iPhone"),
                                                tags$ul(
                                                  tags$li("Öffnen Sie WhatsApp auf Ihrem Smartphone und klicken Sie auf den Chat dessen Verlauf Sie bereitstellen möchten."),
                                                  tags$li("Klicken Sie oben in der Mitte des Chatfensters auf den Namen Ihres Chatpartners."),
                                                  tags$li("Scrollen Sie im Menü nach unten und wählen Sie die Option `Chat exportieren` aus"),
                                                  tags$li("Im folgenden Fenster wählen Sie die Option `Ohne Medien` aus, falls eine Auswahl angezeigt wird."),
                                                  tags$li("Wählen Sie nun ein E-mail Programm aus er Liste aus. Es öffnet sich eine E-mail an welche der Chatverlauf automatisch angehängt ist."),
                                                  tags$li("Geben Sie in das Feld 'An' Ihre eigene E-mail Adresse ein und senden Sie die E-mail an sich selbst ab.")
                                                ),
                                                tags$img(src = "WhatsApp_DataExport_iOS.png",
                                                         style = "width:100%;height:auto;", alt = "iOS export guide"),
                                                tags$ul(
                                                  tags$li("Öffnen Sie das E-mail Postfach an welches Sie den Chatverlauf gerade geschickt haben."),
                                                  tags$li("Laden Sie den Anhang der E-mail herunter. Dies kann entweder eine .zip Datei oder eine .txt Datei sein."),
                                                  tags$li("Laden Sie den heruntergeladenen Chatverlauf im Fenster links (PC), bzw. oben (Smartphone,) auf diese Website hoch."),
                                                  tags$li("Auf der nächsten Seite erhalten Sie die Möglichkeit Ihren anonymisierten Chatverlauf nochmal einzusehen und anschließend abzuschicken.")
                                                )
                                              )
                                            )
                                          ),
                                          
                                          # End sidebar layout
                                        )
                                        
                                        # End tab panel
                               ),
                               
                               ##################################### PARTICIPANT - USER SELECTION PAGE ####
                               tabPanel(display_text[87],
                                        
                                        # Sidebar
                                        sidebarPanel(
                                          
                                          # Info text
                                          h2(display_text[87], align = "center"),
                                          HTML(display_text[90]),
                                          
                                          # spacer
                                          HTML("<br><br>"),
                                          
                                          # input selector
                                          selectInput("person_select",
                                                      label = display_text[91],
                                                      choices = c(""),
                                                      selected = "",
                                                      multiple = FALSE),
                                          
                                          
                                          # action button
                                          actionButton("person_submit",
                                                       display_text[89],
                                                       style = "color: #FFFFFF; background-color: #E2007A; border-color: #E2007A"),
                                        ),
                                        
                                        # Main panel
                                        mainPanel(
                                          
                                          # headline
                                          h2(display_text[87], align = "center"),
                                          
                                          # information
                                          HTML(display_text[58]),
                                          
                                          # table display here
                                          DTOutput("selection_frame"),
                                          
                                          # Display the selected choice
                                          textOutput("selected_choice"),
                                          
                                          # spacer
                                          HTML("<br><br><br><br>"),
                                          
                                        )
                                        
                                        
                               ),
                               
                               
                               ##################################### DATA EXPLORATION PAGE ####
                               tabPanel(display_text[28],
                                        
                                        # Sidebar Panel
                                        sidebarPanel(
                                          
                                          # Info text
                                          #h2(display_text[29], align = "center"),
                                          #HTML(display_text[30]),
                                          #HTML("<br><br>"),
                                          #HTML(display_text[31]),
                                          
                                          # column selection
                                          h3(display_text[32]),
                                          helpText(display_text[33]),
                                          pickerInput("show_vars",
                                                      display_text[34],
                                                      choices = c(""),
                                                      selected = c(""),
                                                      #label = display_text[35],
                                                      multiple = TRUE,
                                                      options  = pickerOptions(
                                                        selectedTextFormat = "count",
                                                        countSelectedText  = "{0} Spalten ausgewählt"#,
                                                        #mobile = TRUE
                                                      ),
                                                      choicesOpt = list(style = c("color:black;font-weight: bold;",
                                                                                  "background:lightgrey;color:black",
                                                                                  "color:black;font-weight: bold;",
                                                                                  "background:lightgrey;color:black",
                                                                                  "background:lightgrey;color:black",
                                                                                  "background:lightgrey;color:black",
                                                                                  "background:lightgrey;color:black",
                                                                                  "color:black;font-weight: bold;",
                                                                                  "background:lightgrey;color:black",
                                                                                  "color:black;font-weight: bold;",
                                                                                  "background:lightgrey;color:black",
                                                                                  "color:black;font-weight: bold;",
                                                                                  "color:black;font-weight: bold;",
                                                                                  "color:black;font-weight: bold;",
                                                                                  "color:black;font-weight: bold;",
                                                                                  "background:lightgrey;color:black",
                                                                                  "color:black;font-weight: bold;",
                                                                                  "color:black;font-weight: bold;",
                                                                                  "color:black;font-weight: bold;"))),
                                          
                                          # Row selection
                                          h3(display_text[36]),
                                          helpText(display_text[37]),
                                          actionButton("excludeRows",display_text[38]),
                                          actionButton("RestoreRows",display_text[39]),
                                          
                                          # Data donation
                                          h3(display_text[40]),
                                          helpText(display_text[41]),
                                          actionButton(inputId = "donation",
                                                       label = display_text[42],
                                                       class = "btn-warning",
                                                       style = "color: #FFFFFF; background-color: #E2007A; border-color: #E2007A")
                                          
                                          # End sidebar panel
                                        ),
                                        
                                        # Main panel
                                        mainPanel(
                                          
                                          # Headline
                                          h1(display_text[43],align = "center"),
                                          HTML("<br>"),
                                          
                                          # Dataframe
                                          DTOutput("frame"),
                                          
                                          # Download buttons
                                          fluidRow(column(1,
                                                          align = "topright",
                                                          downloadButton("downloadSelection",
                                                                         display_text[44])),
                                                   column(1,
                                                          align = "topleft",
                                                          downloadButton("downloadData",
                                                                         display_text[45]),
                                                          offset = 9),),
                                          
                                          # End main panel
                                        )
                                        
                                        # End tab panel
                               ),
                               
                               ##################################### OVERALL RESULTS PAGE ####
                               tabPanel(display_text[46],
                                        
                                        tabsetPanel(type = "tabs",
                                                    
                                                    ##################################### RESULTS: MESSAGES SUBPAGE ####
                                                    tabPanel(display_text[47],
                                                             
                                                             # sidebar panel
                                                             sidebarPanel(h3(display_text[48], align = "center"),
                                                                          tags$p(display_text[49]),
                                                                          
                                                                          # Sender selection
                                                                          h3(display_text[50]),
                                                                          helpText(display_text[51]),
                                                                          checkboxGroupButtons("Sender_input_msg",
                                                                                               "",
                                                                                               display_text[52]),
                                                                          
                                                                          # Time selection
                                                                          h3(display_text[53]),
                                                                          helpText(display_text[54]),
                                                                          dateRangeInput("date_range_messages",
                                                                                         label = display_text[55],
                                                                                         start = "2016-01-01",
                                                                                         end = NULL,
                                                                                         format = "dd-mm-yyyy",
                                                                                         startview = "year",
                                                                                         weekstart = 1,
                                                                                         language = landing_page_language,
                                                                                         autoclose = TRUE,
                                                                                         separator = display_text[56])
                                                                          
                                                                          # End sidebar panel
                                                             ),
                                                             
                                                             # Main Panel
                                                             mainPanel(
                                                               
                                                               # Plot 1
                                                               h1(display_text[57],align = "center"),
                                                               HTML(display_text[58]),
                                                               HTML("<br><br>"),
                                                               addSpinner(plotOutput("message1",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                               # Plot 2
                                                               h1(display_text[59],align = "center"),
                                                               HTML("<br><br>"),
                                                               addSpinner(plotOutput("tokensbwah1",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                               # plot 3
                                                               addSpinner(plotOutput("tokensbwah2",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8")
                                                               
                                                               # End main panel
                                                             ),
                                                             
                                                             # end tab panel
                                                             width = 6, offset = 5),
                                                    
                                                    ##################################### RESULTS: LINKS SUBPAGE ####
                                                    tabPanel(display_text[60],
                                                             
                                                             # sidebar panel
                                                             sidebarPanel(h3(display_text[48], align = "center"),
                                                                          tags$p(display_text[61]),
                                                                          
                                                                          # sender selection
                                                                          h3(display_text[50]),
                                                                          helpText(display_text[51]),
                                                                          checkboxGroupButtons("Sender_input_links",
                                                                                               "",
                                                                                               display_text[62]),
                                                                          
                                                                          # timespan selection
                                                                          h3(display_text[55]),
                                                                          helpText(display_text[54]),
                                                                          dateRangeInput("date_range_links",
                                                                                         label = display_text[55],
                                                                                         start = "2016-01-01",
                                                                                         end = NULL,
                                                                                         format = "dd-mm-yyyy",
                                                                                         startview = "year",
                                                                                         weekstart = 1,
                                                                                         language = landing_page_language,
                                                                                         autoclose = TRUE,
                                                                                         separator = display_text[56]),
                                                                          
                                                                          # Link Minimum selection
                                                                          h3(display_text[63]),
                                                                          helpText(display_text[64]),
                                                                          sliderInput("LinkMinimum",
                                                                                      "",
                                                                                      min = 1,
                                                                                      max = 100,
                                                                                      value = 5)
                                                                          
                                                                          # End sidebar panel
                                                             ),
                                                             
                                                             # Main Panel
                                                             mainPanel(
                                                               
                                                               # Plot 1
                                                               h3(display_text[65], align = "center"),
                                                               HTML(display_text[58]),
                                                               addSpinner(plotOutput("links4",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                               # plot 2
                                                               addSpinner(plotOutput("links2",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                               # plot 3
                                                               addSpinner(plotOutput("links1",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                             ),
                                                             
                                                             width = 6, offset = 5),
                                                    
                                                    ##################################### RESULTS: SMILIES SUBPAGE ####
                                                    tabPanel(display_text[66],
                                                             
                                                             # sidebar panel
                                                             sidebarPanel(h3(display_text[48], align = "center"),
                                                                          tags$p(display_text[67]),
                                                                          
                                                                          # sender selection
                                                                          h3(display_text[50]),
                                                                          helpText(display_text[51]),
                                                                          checkboxGroupButtons("Sender_input_smilies",
                                                                                               "",
                                                                                               display_text[52]),
                                                                          
                                                                          # time range selection
                                                                          h3(display_text[53]),
                                                                          helpText(display_text[54]),
                                                                          dateRangeInput("date_range_smilies",
                                                                                         label = display_text[55],
                                                                                         start = "2016-01-01",
                                                                                         end = NULL,
                                                                                         format = "dd-mm-yyyy",
                                                                                         startview = "year",
                                                                                         weekstart = 1,
                                                                                         language = landing_page_language,
                                                                                         autoclose = TRUE,
                                                                                         separator = display_text[56]),
                                                                          
                                                                          # smilie minimum selection
                                                                          h3(display_text[63]),
                                                                          helpText(display_text[68]),
                                                                          sliderInput("SmilieMinimum",
                                                                                      "", min = 1,
                                                                                      max = 100,
                                                                                      value = 5)
                                                                          
                                                             ),
                                                             
                                                             # Main Panel
                                                             mainPanel(
                                                               
                                                               # Plot 1
                                                               h3(display_text[69], align = "center"),
                                                               HTML(display_text[58]),
                                                               addSpinner(plotOutput("smilies4",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                               # Plot 2
                                                               addSpinner(plotOutput("smilies2",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                               # Plot 3
                                                               addSpinner(plotOutput("smilies1",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                               # end main panel
                                                             ),
                                                             
                                                             # end tabpanel
                                                             width = 6, offset = 5),
                                                    
                                                    ##################################### RESULTS: EMOJI SUBPAGE ####
                                                    tabPanel(display_text[70],
                                                             
                                                             # sidebar panel
                                                             sidebarPanel(h3(display_text[48], align = "center"),
                                                                          tags$p(display_text[71]),
                                                                          
                                                                          # sender selection
                                                                          h3(display_text[50]),
                                                                          helpText(display_text[51]),
                                                                          checkboxGroupButtons("Sender_input_emoji",
                                                                                               "",
                                                                                               display_text[62]),
                                                                          
                                                                          # timeframe selection
                                                                          h3(display_text[53]),
                                                                          helpText(display_text[54]),
                                                                          dateRangeInput("date_range_emoji",
                                                                                         label = display_text[55],
                                                                                         start = "2016-01-01",
                                                                                         end = NULL,
                                                                                         format = "dd-mm-yyyy",
                                                                                         startview = "year",
                                                                                         weekstart = 1,
                                                                                         language = landing_page_language,
                                                                                         autoclose = TRUE,
                                                                                         separator = display_text[56]),
                                                                          
                                                                          # minimum emoji selection
                                                                          h3(display_text[63]),
                                                                          helpText(display_text[72]),
                                                                          sliderInput("EmojiMinimum",
                                                                                      "",
                                                                                      min = 1,
                                                                                      max = 100,
                                                                                      value = 50)
                                                                          
                                                                          
                                                                          # end sidebar panel
                                                             ),
                                                             
                                                             # Main Panel
                                                             mainPanel(
                                                               
                                                               # Plot 1
                                                               h3(display_text[73],
                                                                  align = "center"),
                                                               HTML(display_text[58]),
                                                               addSpinner(plotOutput("emoji4",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                               # Plot 2
                                                               addSpinner(plotOutput("emoji2",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                               # Plot 3
                                                               addSpinner(plotOutput("emoji1",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                               # end main panel
                                                             ),
                                                             
                                                             # end tabpanel
                                                             width = 6, offset = 5),
                                                    
                                                    
                                                    ##################################### RESULTS: REPLYTIMES SUBPAGE ####
                                                    tabPanel(display_text[74],
                                                             
                                                             # sidebar panel
                                                             sidebarPanel(h3(display_text[48], align = "center"),
                                                                          
                                                                          tags$p(display_text[75]),
                                                                          
                                                                          # sender selection
                                                                          h3(display_text[50]),
                                                                          helpText(display_text[51]),
                                                                          checkboxGroupButtons("Sender_input_replies",
                                                                                               "",
                                                                                               display_text[52]),
                                                                          
                                                                          # timeframe selection
                                                                          h3(display_text[53]),
                                                                          helpText(display_text[54]),
                                                                          dateRangeInput("date_range_replies",
                                                                                         label = display_text[55],
                                                                                         start = "2016-01-01",
                                                                                         end = NULL,
                                                                                         format = "dd-mm-yyyy",
                                                                                         startview = "year",
                                                                                         weekstart = 1,
                                                                                         language = landing_page_language,
                                                                                         autoclose = TRUE,
                                                                                         separator = display_text[56])
                                                                          
                                                                          
                                                             ),
                                                             
                                                             # Main Panel
                                                             mainPanel(
                                                               
                                                               # Plot 1
                                                               h3(display_text[74], align = "center"),
                                                               HTML(display_text[58]),
                                                               addSpinner(plotOutput("replytime1",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8"),
                                                               HTML("<br><br>"),
                                                               
                                                               # Plot 2
                                                               addSpinner(plotOutput("replytime2",
                                                                                     height = "600px"),
                                                                          spin = "circle",
                                                                          color = "#1E8CC8")
                                                               
                                                               # End main panel
                                                             ),
                                                             
                                                             # end tab panel
                                                             width = 6, offset = 5)
                                                    
                                                    
                                                    # End tabset panel
                                        )
                                        
                                        
                                        
                                        # End tab Panel
                               ),
                               
                               ##################################### RESULTS: IMPRESSUM PAGE ####
                               tabPanel(display_text[76],
                                        column(tags$p(
                                          HTML(display_text[77])),
                                          width = 6, offset = 5))
                               
                               # End navbarpage
                    ),
                    
                    gesis_footer
                    
                    # End ui
)

###################################################################################### SECURING APP WITH SHINYMANAGER #####

# Let shinymanager build the login form, then add branding around its card.
secure_ui <- shinymanager::secure_app(
  app_ui,
  language = landing_page_language,
  head_auth = tagList(
    gesis_page_styles,
    tags$style(HTML("
      #auth-auth-mod.gesis-login {
        display: flex;
        flex-direction: column;
      }
      .gesis-login > .gesis-login-header,
      .gesis-login > footer.page-footer {
        flex: 0 0 auto;
      }
      /* Replace shinymanager's fixed top spacer with responsive row padding. */
      .gesis-login > br,
      .gesis-login > div[style='height: 70px;'] {
        display: none;
      }
      .gesis-login > .row {
        box-sizing: border-box;
        display: flex;
        flex: 1 0 auto;
        align-items: center;
        justify-content: center;
        margin: 0;
        padding: clamp(1rem, 4vw, 3rem) 1rem;
      }
      .gesis-login > .row > .col-sm-4 {
        box-sizing: border-box;
        width: 100%;
        max-width: 560px;
        margin: 0;
        padding: 0;
      }
      .gesis-login > .row > .col-sm-4 > .panel {
        margin-bottom: 0;
      }
    "))
  )
)

gesis_login_header <- tags$header(
  class = "gesis-login-header",
  tags$div(id = "gesis-micro-header", includeHTML("www/gesis-micro-header.html")),
  includeHTML("www/gesis-microsite-banner.html")
)

ui <- function(request) {
  page <- secure_ui(request)
  login <- htmltools::tagQuery(page)$find("#auth-auth-mod.panel-auth")
  if (login$length() == 0) return(page)

  login$
    addClass("gesis-login")$
    prepend(gesis_login_header)$
    append(gesis_footer)$
    allTags()
}







