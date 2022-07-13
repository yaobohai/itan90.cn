{% if page.comments %}

  {% if (theme.duoshuo and theme.duoshuo.shortname) or theme.duoshuo_shortname %}
    <div class="comments" id="comments">
      <div class="ds-thread" data-thread-key="{{ page.path }}"
           data-title="{{ page.title }}" data-url="{{ page.permalink }}">
      </div>
    </div>

  {% elseif theme.facebook_sdk.enable and theme.facebook_comments_plugin.enable %}
    <div class="comments" id="comments">
      <div class="fb-comments"
           data-href="{{ page.permalink }}"
           data-numposts="{{ theme.facebook_comments_plugin.num_of_posts }}"
           data-width="{{ theme.facebook_comments_plugin.width }}"
           data-colorscheme="{{ theme.facebook_comments_plugin.scheme }}">
      </div>
    </div>

  {% elseif theme.vkontakte_api.enable and theme.vkontakte_api.comments %}
    <div class="comments" id="comments">
      <div id="vk_comments"></div>
    </div>

  {% elseif theme.disqus.enable %}
    <div class="comments" id="comments">
      <div id="disqus_thread">
        <div id="dsqjs">
          <section class="dsqjs-info">
            <p id="dsqjs-load-disqus" class="dsqjs-message">评论完整模式加载中...如果长时间无法加载，请针对 disq.us | disquscdn.com | disqus.com 启用代理</p>
          </section>
        </div>
      </div>
    </div>
  {% elseif theme.twikoo.enable %}
       function wangzhi(e){
        http = e.slice(0,4)
        https = e.slice(0,5)
        if (http == "http" || https == "https" ){
             return e
        } else if (e == "" || e == null || e == undefined){
          return e
        } else {
          e = 'http://'+ e
          return e
        }
    }
function newcomment() {
    twikoo.getRecentComments({
        envId: 'cloudbase-70cf3a', // 环境 ID
        pageSize: 7, // 获取多少条，默认：10，最大：100
        includeReply: false // 是否包括最新回复，默认：false
    }).then(function (res) {
        console.log(res);
        var hotComments = $("#hot-comments");
        for (var i = 0; i < res.length; i++) {
            if (i === 0) {
                console.log(res[0]);
            }
            var nick = res[i].nick;//访客姓名
            var content = res[i].commentText;//评论内容
            var newcontent = content.substring(0, 50); //字数截取后评论内容
            var url = res[i].url;//文章链接
            var avatar = res[i].avatar;//评论者头像
            var link = wangzhi(res[i].link);//评论者网址
            var updatedAt = res[i].relativeTime;//评论时间
            var commentId = '#' + res[i].id;//评论id
            hotComments.append('<li class="px1 pb2 flex items-center"><img style="width: 40px;height:40px" class="circle mx1 listavatar" src="' + avatar + '"><div class="w100"><div class="flex justify-between"><div class="h6 listauthor overflow-hidden" title="' + nick + '"><a  target="_blank" rel="noopener external nofollow noreferrer" href="' + link + '">' + nick + '</a></div><span class="h6 mr1 listdate wenzi hang1">' + updatedAt + '</span></div> <a href="' + url + commentId + '"><div class="h5 list-comcontent overflow-hidden">' + newcontent + '</div></a></div></li>');
        }
    }).catch(function (err) {
        console.error(err);
    });
}

$(function () {
    newcomment();//调用newcomment
});

  {% elseif theme.hypercomments_id %}
    <div class="comments" id="comments">
      <div id="hypercomments_widget"></div>
    </div>

  {% elseif theme.youyan_uid %}
    <div class="comments" id="comments">
      <div id="uyan_frame"></div>
    </div>

  {% elseif theme.livere_uid %}
    <div class="comments" id="comments">
      <div id="lv-container" data-id="city" data-uid="{{ theme.livere_uid }}"></div>
    </div>

  {% elseif theme.changyan.appid and theme.changyan.appkey %}
    <div class="comments" id="comments">
      <div id="SOHUCS"></div>
    </div>

  {% elseif theme.gitment.enable %}
    <div class="comments" id="comments">
      {% if theme.gitment.lazy %}
        <div onclick="showGitment()" id="gitment-display-button">{{ __('gitmentbutton') }}</div>
        <div id="gitment-container" style="display:none"></div>
      {% else %}
        <div id="gitment-container"></div>
      {% endif %}
    </div>

  {% elseif theme.valine.appid and theme.valine.appkey %}
    <div class="comments" id="comments">
      <div id="vcomments"></div>
    </div>
  {% endif %}

{% endif %}
{% include '../_third-party/comments/index.swig' %}
