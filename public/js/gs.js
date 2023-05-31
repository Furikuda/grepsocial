function getUnseen(nb=100){
    $.ajax({
        url: "/unseen?nb="+nb,
        type: "GET",
        dataType: "json",
        success: function(data, textStatus) {
            showPics(data,true);
        },
        error: function (data) {
//            toastr.options.timeOut = 2500;
//            toastr.options.positionClass= "toast-top-center";
//            toastr.error(data.responseText);
			console.log("Error: "+data.responseText); 
        }
    });
}

function escapeXml(txt) {
    return txt.replace(/[<>&'"]/g, function (c) {
        switch (c) {
            case '<': return '&lt;';
                case '>': return '&gt;';
                case '&': return '&amp;';
                case '\'': return '&apos;';
                case '"': return '&quot;';
            }
    });
}

function urlToSVGPic(url) {
    var text_tag = "<text x='0' y='15' fill='blue' font-size='16'>";

    var uri = new URL(url);
    var txt_escaped = escapeXml(uri.hostname + uri.pathname);
    var bits = txt_escaped.match(/.{1,30}/g)
    for (i=0; i<bits.length; i++) {
      text_tag += "<tspan x='0' dy='1.2em'>"+bits[i]+"</tspan>";
    }

    text_tag += "</text>";
    var svg = "<svg xmlns='http://www.w3.org/2000/svg' version='1.1'>"+text_tag+"</svg>"
    var img_data = "data:image/svg+xml;utf8,"+svg;
    return img_data;
}

function showPics(d,save=true) {
    var sessid = d['sessid'];
    var data = d['data'];
	if (typeof data === 'undefined') {
		return;
	}
    if (data.length == 0) {
        var container = $('#container');
        $('<div/>')
            .appendTo(container)
            .text("That's all folks!") 
        return;
    }
    var form = $('#mark')[0];
    form.action = '/markseen?sessid='+sessid;
    var itemList = $('#container');
   	$.each(data, function(i) {
        var item = data[i];
		var li = $('<div/>')
        .addClass('thumb')
        .addClass('item')
        .addClass(item['site']+'-item')
        .addClass(item['type']);
        if (window.location.hash == '#debug') {
            li.attr('data-tooltip', item['debug'])
        }
        li.appendTo(itemList);

		var aaa = $('<a/>')
        .attr('href',item['source'])
        .attr('target','#blank');
        if (item['thumb'] == "" || item['thumb'] == null) {
            aaa.css({'background-image': 'url("'+ urlToSVGPic(item['url']) +'")'})
        } else  {
            if (item['site'] == 'Furaffinity') {
              pic_url_elem = item['thumb'].split('/')
              pic_filename = pic_url_elem[pic_url_elem.length - 1];
              aaa.css({'background-image': 'url("/pics/furaffinity/'+pic_filename+'")'})
            } else {
              aaa.css({'background-image': 'url("'+item['thumb']+'")'})
            }
        }
        aaa.appendTo(li);
        var overlay = $('<img/>')
        .attr('src',"/pics/"+item['site']+".png")
        .addClass('overlay')
        .appendTo(li);
        if (save) {
            var c_label  = $('<label/> ')
                .addClass("checkbox-label")
                .html("&nbsp;&nbsp;&nbsp;Save")
                .appendTo(li);
            var c_id=[item['source'],item['id']].join("-@@|@@-");
            var checkbox = $('<input type="checkbox" id="'+c_id+'"/>')
                .addClass("save-checkbox")
                .change(function() {
                    $.post("/save", {id: this.id, checked: this.checked});
                })
                .prependTo(c_label);
        }
    });
}
