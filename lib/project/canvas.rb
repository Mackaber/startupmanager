#encoding: utf-8
module Project::Canvas
  
  # Letter-landscape (11" x 8.5") is 792x612 points, with 0,0 at the bottom-left
  # 0.5 inch margins yields 720x540
  # 1 inch at top for header, 0.5 inch at bottom for footer
  # leaves 720x432 for content
  def canvas_pdf(date = Date.today)
    start_time = date.beginning_of_week.midnight
    end_time = start_time + 1.week - 1
    
    project = self
    pdf = Prawn::Document.new(
      :page_layout => :landscape
    ) do
      
      bounding_box [0, 539], :width => 720, :height => 72 do
        text project.name, :align => :center, :style => :bold, :size => 24
        text "Week of #{date.strftime("%B %d, %Y")}", :align => :center
      end
      
      bounding_box [0, 35], :width => 720, :height => 36 do
        text_box "The Canvas is adapted from businessmodelgeneration.com and is licensed under the Creative Commons Attribution-Share Alike 3.0 Unported License.", :at => [0, 18], :width => 576, :align => :left, :size => 6
        text_box "www.leanlaunchlab.com", :at => [576, 20], :width => 144, :align => :right, :size => 9
      end
      
      geometry = {
        "key_partners" => [0, 467, 144, 288],
        "key_activities" => [144, 467, 144, 144],
        "key_resources" => [144, 323, 144, 144],
        "value_propositions" => [288, 467, 144, 288],
        "customer_relationships" => [432, 467, 144, 144],
        "channels" => [432, 323, 144, 144],
        "customer_segments" => [576, 467, 144, 288],
        "cost_structure" => [0, 179, 360, 144],
        "revenue_stream" => [360, 179, 360, 144]
      }
      
      stroke_color "eeeeee"
      
      y = 45
      while (y < 468) do
        stroke { line [0, y], [719, y]}
        y += 9
      end
      
      x = 9
      while (x < 720) do
        stroke { line [x, 36], [x, 467] }
        x += 9
      end
      
      html_canvas_width = 972.0
      html_canvas_height = 564.0
      
      stroke_color "aaaaaa"
      
      geometry.each do |k,v|
        box = Box.find_by_name(k)
        stroke { rectangle [v[0], v[1]], v[2], v[3] }
        text_box (project.canvas_startup_headers ? box.startup_label : box.label), :at => [v[0]+6, v[1]-6], :style => :bold
      end
      
      project.canvas_items.items_for_week(date).order("z asc").each do |canvas_item|
        x = (canvas_item.x || 0) / html_canvas_width * 1.01
        y = 1 - (canvas_item.y || 0) / html_canvas_height * 1.01
        image "#{Rails.root}/app/assets/images/v2/canvas-item-#{canvas_item.display_color}.png", :at => [x * 720, y * 432 + 36], :scale => 0.9
        
        if (canvas_item.item_status_id == ItemStatus.cached_find_by_status("valid").id)
          image "#{Rails.root}/app/assets/images/v2/right.png", :at => [x * 720 + 50, y * 432 + 36 - 35], :scale => 0.75
        elsif (canvas_item.item_status_id == ItemStatus.cached_find_by_status("invalid").id)
          image "#{Rails.root}/app/assets/images/v2/cross.png", :at => [x * 720 + 50, y * 432 + 36 - 40], :scale => 0.75
        end

        color = (project.canvas_highlight_new && canvas_item.original.created_at >= start_time && canvas_item.original.created_at <= end_time) ? "ff0000" : "000000"        
        formatted_text_box [
          {:text => canvas_item.text, :size => 10, :color => color}
        ], :at => [x * 720, y * 432 + 30], :width => 72, :height => 72, :align => :center
      end
    
    end
    return pdf.render
  end
  
end