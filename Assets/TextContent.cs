using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class TextContent : MonoBehaviour
{
    // Start is called before the first frame update

    public string[] subtitle_contents;
    public Text subtitle;
    public int duration;

    void Start()
    {
        StartCoroutine(changeSubtitles(duration));
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public IEnumerator changeSubtitles(int duration)
    {
        for(int i = 0; i < subtitle_contents.Length; i++)
        {
            subtitle.text = subtitle_contents[i];
            yield return new WaitForSeconds(duration);
        }
    }
}
